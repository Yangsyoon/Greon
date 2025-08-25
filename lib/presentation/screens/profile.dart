import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/core/router/app_router.dart';
import 'package:greon/presentation/screens/settings_page.dart';
import 'package:greon/presentation/widgets/top_row.dart';
import 'package:greon/presentation/widgets/user_logged_profile_container.dart';
import 'package:greon/presentation/widgets/unlogged_profile_container.dart';
import 'package:greon/presentation/screens/user_info_input_page.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/user_bloc/user_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _isNotificationEnabled = status == PermissionStatus.granted;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      final result = await Permission.notification.request();
      setState(() {
        _isNotificationEnabled = result == PermissionStatus.granted;
      });
    } else {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    SvgPicture arrowForward = SvgPicture.asset(
      AppAssets.LeftArrow,
      width: AppDimensions.normalize(6),
    );

    return Scaffold(
      body: Padding(
        padding: Space.h1!,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(AppAssets.greonAppBar, height: 40),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "마이페이지",
                  style: AppText.h2b?.copyWith(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      if (state is UserLogged) {
                        final user = firebase.FirebaseAuth.instance.currentUser;
                        final email = user?.email ?? '이메일 없음';
                        final image = user?.photoURL;

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final nickname = data?['nickname'] ?? '닉네임 없음';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Space.y!,
                                userLoggedProfileContainer(context, nickname, email, image),
                                Space.yf(1),
                                _buildLoggedInSection(context, arrowForward),
                              ],
                            );
                          },
                        );
                      } else {
                        return Column(
                          children: [
                            Space.y!,
                            unloggedProfileContainer(context),
                          ],
                        );
                      }
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLoggedInSection(BuildContext context, SvgPicture arrowForward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          '내 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),

        // 🔽 기존에 버튼 눌러서 이동하던 settings_page 내용 바로 표시
        _buildSettingRow(
          context: context,
          title: '회원 정보 수정',
          onTap: () => Navigator.pushNamed(context, '/user_info_input'),
        ),
        const SizedBox(height: 12),
        _buildSettingRow(
          context: context,
          title: '배송지 관리',
          onTap: () => Navigator.pushNamed(context, '/addresses'),
        ),
        const SizedBox(height: 12),
        _buildSettingRow(
          context: context,
          title: '맞춤 정보',
          onTap: () => Navigator.pushNamed(context, '/custom_info'),
        ),
        const SizedBox(height: 12),
        _buildSettingRow(
          context: context,
          title: '알림 설정',
          onTap: () => Navigator.of(context).pushNamed(AppRouter.notificationSettings),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        const Text(
          '계정',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 12),
        _buildSettingRow(
          context: context,
          title: '비밀번호 변경',
          onTap: () => Navigator.pushNamed(context, '/change_password'),
        ),
        const SizedBox(height: 12),
        _buildSettingRow(
          context: context,
          title: '로그아웃',
          onTap: () {
            // 로그아웃 처리
          },
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // 테스트 알림 시험
  Future<void> createTestNotification(String fcmToken) async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(minutes: 1)); // 1분 뒤 알림

    final docRef = FirebaseFirestore.instance.collection('notification_requests').doc();

    await docRef.set({
      'fcm_token': fcmToken,
      'title': '테스트 알림',
      'body': '앱이 꺼져 있어도 알림이 오는지 확인해보세요!',
      'scheduled_time': Timestamp.fromDate(scheduledTime),
      'sent': false,
      'created_at': Timestamp.now(),
    });

    print('테스트 알림 문서 생성 완료: ${docRef.id}');
  }


  Widget _settingButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SettingsPage()),
        );
      },
      child: const Text('설정 열기'),
    );
  }

  Widget _notificationSettingButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(AppAssets.Bell),
            Space.xf(),
            Text("알림", style: AppText.b1b),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            openAppSettings(); // 시스템 설정으로 이동
          },
          icon: Icon(Icons.settings, color: Colors.black),
          label: Text(
            "알림 설정 열기",
            style: AppText.b2?.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }


  Widget _buildPlantActionButtons(BuildContext context) {
    final buttonData = [
      {
        'label': '내 식물 보기',
        'icon': Icons.local_florist,
        'color': Colors.black,
        'onTap': () => Navigator.of(context).pushNamed(AppRouter.myPlants),
      },
      {
        'label': '내 식물 추가',
        'icon': Icons.add,
        'color': Colors.black,
        'onTap': () => Navigator.of(context).pushNamed(AppRouter.registerPlant),
      },
      {
        'label': '식물 캘린더',
        'icon': Icons.calendar_month,
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).pushNamed(AppRouter.calendar),
      },
      {
        'label': '위시리스트',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'onTap': () => Navigator.of(context).pushNamed(AppRouter.wishlist),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.normalize(6)),
      child: GridView.count(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.normalize(6),
        mainAxisSpacing: AppDimensions.normalize(6),
        childAspectRatio: 3 / 2,
        children: buttonData.map((btn) {
          return GestureDetector(
            onTap: btn['onTap'] as VoidCallback,
            child: Container(
              decoration: BoxDecoration(
                color: btn['color'] as Color,
                borderRadius: BorderRadius.circular(AppDimensions.normalize(5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(AppDimensions.normalize(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(btn['icon'] as IconData, color: Colors.white),
                  SizedBox(width: AppDimensions.normalize(3)),
                  Flexible(
                    child: Text(
                      btn['label'] as String,
                      style: AppText.b1?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _iconRow(BuildContext context, String title, String iconPath, String? route, Widget arrow, {Color? iconColor}) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.normalize(5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Row(
                children: [
                  SvgPicture.asset(iconPath, height: AppDimensions.normalize(14), color: iconColor),
                  Space.xf(),
                  Text(title, style: AppText.b1b),
                ],
              ),
            ),
            arrow,
          ],
        ),
      ),
    );
  }

  Widget _iconRowWithSystemIcon(BuildContext context, String title, IconData iconData, String? route, Widget arrow, {
    Color? iconColor,
    VoidCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap: onTapOverride ?? () {
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.normalize(5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, color: iconColor ?? Colors.black),
                Space.xf(),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(title, style: AppText.b1b),
                ),
              ],
            ),
            arrow
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppText.h3b?.copyWith(color: Colors.black));
  }
}
