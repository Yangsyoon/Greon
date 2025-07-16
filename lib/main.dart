import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'application/post_bloc/post_bloc.dart';
import 'application/post_bloc/post_event.dart';
import 'core/app/app.dart';
import 'core/observer/bloc_observer.dart';
import 'data/data_sources/local/user_local_data_source.dart';
import 'data/repositories/post_repository.dart';
import 'di/cubits.dart';
import 'di/di.dart' as di;
import 'di/product.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// 1. FCM 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 알림: ${message.notification?.title}');
  // 필요하다면 로컬 알림 표시 등 추가 가능
}

/// 2. 로컬 알림 및 채널 초기화
Future<void> _initializeLocalNotifications() async {
  tz.initializeTimeZones();

  const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInitSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Android 알림 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'test_channel',
    'Test Notifications',
    description: '테스트용 알림 채널입니다.',
    importance: Importance.max,
  );
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(channel);

  // Android 13+ 알림 권한 요청
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      debugPrint("🔔 Notification permission status: $status");
      if (await Permission.notification.isDenied) {
        openAppSettings();
      }
    }
  }

  // iOS 알림 권한 요청
  final iosPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
}

/// 3. FCM 권한 및 리스너 설정
Future<void> _setupFCM(BuildContext context) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  print('🔔 FCM 권한 상태: ${settings.authorizationStatus}');

  // 포그라운드 메시지 수신
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('포그라운드 알림: ${message.notification?.title}');
    // 필요시 로컬 알림 표시
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails('test_channel', 'Test Notifications'),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  });

  // 알림 클릭시 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('알림 클릭: ${message.data}');
    // 예시: 특정 화면 이동
    // Navigator.pushNamed(context, '/somePage');
  });

  // userLocalDataSource 인스턴스 생성


  // FCM 토큰 저장
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // userLocalDataSource 인스턴스 생성
      final userLocalDataSource = UserLocalDataSourceImpl(
        sharedPreferences: await SharedPreferences.getInstance(),
        secureStorage: const FlutterSecureStorage(),
      );
      final idToken = await user.getIdToken();
      if (idToken != null) {
        await userLocalDataSource.saveToken(idToken);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcm_token': token});
      print('✅ FCM 토큰 저장: $token');

    }

    //wishlist 때문에 추가
    if (user != null) {
      registerCubits(userId: user.uid);
    }
  }


  // 토큰 갱신 모니터링
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcm_token': newToken});
      print('🔄 FCM 토큰 갱신: $newToken');
      final userLocalDataSource = UserLocalDataSourceImpl(
        sharedPreferences: await SharedPreferences.getInstance(),
        secureStorage: const FlutterSecureStorage(),
      );
      await userLocalDataSource.saveToken(newToken);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  // 1. 백그라운드 핸들러 등록 (main 함수 내에서 반드시 등록)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  di.sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    await di.init(userId: currentUser.uid);
  }
  registerProductFeature();

  Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initializeLocalNotifications();

  runApp(
    Phoenix(
      child: MyAppWrapper(),
    ),
  );
}

/// 앱 초기화 후 알림 권한 및 FCM 리스너 실행
class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({super.key});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _setupFCM(context); // context 전달
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint("Notification permission status: $status");
      if (status.isDenied || status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PostBloc>(
          create: (_) => PostBloc(PostRepository())..add(LoadPosts()),
        ),
        // 다른 Bloc들도 여기에 추가 가능
      ],
      child: const MyApp(),
    );
  }
}
