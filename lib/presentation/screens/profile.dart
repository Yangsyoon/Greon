import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/core/router/app_router.dart';
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
        padding: Space.hf(1.1),
        child: SafeArea(
          minimum: EdgeInsets.only(top: AppDimensions.normalize(20)),
          child: Column(
            children: [
              TopRow(isFromHome: false, context: context),
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
        _buildPlantActionButtons(context),
        Space.yf(2),
        _sectionTitle("내 계정"),
        Space.yf(1),
        _iconRow(context, "주문 내역", AppAssets.Archive, AppRouter.orders, arrowForward),
        _iconRow(context, "배송지 관리", AppAssets.Marker, AppRouter.addresses, arrowForward),
        _iconRow(context, "계정 정보 수정", AppAssets.Profile, null, arrowForward, iconColor: AppColors.CommonCyan),
        _iconRow(context, "비밀번호 변경", AppAssets.Lock, null, arrowForward),
        _iconRowWithSystemIcon(
          context,
          "회원 정보 입력",
          Icons.info_outline,
          null,
          arrowForward,
          iconColor: AppColors.CommonCyan,
          onTapOverride: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserInfoInputPage()));
          },
        ),
        Space.yf(2),
        _sectionTitle("설정"),
        Space.yf(1),
        _notificationSettingButton(),
        Space.yf(3),
        Center(child: Text("버전 1.0", style: AppText.b1b)),
        Space.yf(1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.Whats, height: AppDimensions.normalize(15)),
            SizedBox(width: AppDimensions.normalize(6)),
            SvgPicture.asset(AppAssets.Noti, height: AppDimensions.normalize(15)),
            SizedBox(width: AppDimensions.normalize(6)),
            SvgPicture.asset(AppAssets.Music, height: AppDimensions.normalize(15)),
          ],
        ),
        Space.yf(2),
      ],
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
          icon: Icon(Icons.settings, color: AppColors.CommonCyan),
          label: Text(
            "알림 설정 열기",
            style: AppText.b2?.copyWith(color: AppColors.CommonCyan),
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
        'color': AppColors.CommonCyan,
        'onTap': () => Navigator.of(context).pushNamed(AppRouter.myPlants),
      },
      {
        'label': '내 식물 추가',
        'icon': Icons.add,
        'color': AppColors.CommonCyan,
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
    return Text(title, style: AppText.h3b?.copyWith(color: AppColors.CommonCyan));
  }
}
