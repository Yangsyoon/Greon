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

import 'application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import 'application/bottom_navbar_cubit/navigation_state.dart';
import 'application/post_bloc/post_bloc.dart';
import 'application/post_bloc/post_event.dart';
import 'core/app/app.dart';
import 'core/observer/bloc_observer.dart';
import 'data/data_sources/local/user_local_data_source.dart';
import 'data/repositories/post_repository.dart';
import 'di/di.dart' as di;
import 'di/product.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 전역 변수로 플러그인 인스턴스 생성
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// 1. FCM 백그라운드 핸들러 (변경 없음)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('백그라운드 알림: ${message.notification?.title}');
}

/// 2. 알림 관련 초기화 (하나의 함수로 통합)
Future<void> initializeNotifications() async {
  // 시간대 초기화
  tz.initializeTimeZones();

  // 로컬 알림 기본 설정
  const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInitSettings = DarwinInitializationSettings(
    requestAlertPermission: false, // 권한 요청은 별도로 관리
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(android: androidInitSettings, iOS: iosInitSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Android 알림 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'test_channel', 'Test Notifications',
    description: '테스트용 알림 채널입니다.', importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// 3. FCM 설정 및 토큰 관리 (하나의 함수로 통합)
Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // 1. 알림 권한 요청 (iOS & Android 13+)
  final settings = await messaging.requestPermission(
    alert: true, announcement: false, badge: true, carPlay: false,
    criticalAlert: false, provisional: false, sound: true,
  );
  print('🔔 FCM 권한 상태: ${settings.authorizationStatus}');
  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    // 권한이 거부되었을 때 설정창을 여는 등의 처리 가능
    // openAppSettings();
  }

  // 2. 포그라운드 메시지 수신 리스너
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('포그라운드 알림: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode, message.notification!.title, message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails('test_channel', 'Test Notifications'),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );
    }
  });

  // 3. 알림 클릭 리스너
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('알림 클릭: ${message.data}');
    // TODO: 알림 데이터에 따라 특정 화면으로 이동하는 로직 구현
  });

  // 4. FCM 토큰 저장 및 갱신 (로그인 상태일 때만)
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      final token = await messaging.getToken();
      if (token != null) {
        print('✅ FCM 토큰 저장: $token');
        // DI를 통해 UserLocalDataSource 인스턴스 가져오기
        final userLocalDataSource = di.sl<UserLocalDataSource>();
        final idToken = await user.getIdToken();
        // idToken이 null이 아닐 경우에만 saveToken 함수를 호출합니다.
        if (idToken != null) {
          await userLocalDataSource.saveToken(idToken);
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcm_token': token},
          SetOptions(merge: true), // merge:true로 다른 필드를 덮어쓰지 않도록 함
        );
      }
    }
  });

  messaging.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔄 FCM 토큰 갱신: $newToken');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcm_token': newToken},
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 로컬 알림 초기화
  await initializeNotifications();

  // FCM 설정 (권한 요청 및 리스너 등록)
  // main 함수에서 호출하여 앱 생명주기 동안 리스너가 활성화되도록 함
  await setupFCM();

  // 의존성 주입 초기화
  await di.init();

  Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(Phoenix(child: const MyAppWrapper()));
}

// MyAppWrapper는 더 이상 알림 관련 코드를 가질 필요가 없음
class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PostBloc>(
          create: (_) => PostBloc(di.sl())..add(LoadPosts()), // DI 사용
        ),
        BlocProvider<NavigationCubit>(
          create: (_) => NavigationCubit(),
        ),
      ],
      child: BlocListener<NavigationCubit, NavigationState>(
        listener: (context, state) {},
        child: const MyApp(),
      ),
    );
  }
}