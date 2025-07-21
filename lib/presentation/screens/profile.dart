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

import '../../application/user_bloc/user_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<String> getMyNickname(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return snapshot.data()?['nickname'] ?? '알 수 없음';
    } catch (e) {
      return '알 수 없음';
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
                            unLoggedProfileContainer(context),
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
        childAspectRatio: 3 / 2, // 가로:세로 비율 3:2
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

  Widget _buildLoggedInSection(BuildContext context, SvgPicture arrowForward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlantActionButtons(context), // 식물 관련 4개 버튼 (2x2 그리드)
        Space.yf(2), // 넉넉한 간격

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
        _notificationSwitch(),

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

  Widget _iconRowWithSystemIcon(
      BuildContext context,
      String title,
      IconData iconData,
      String? route,
      Widget arrow, {
        Color? iconColor,
        VoidCallback? onTapOverride,
      }) {
    return GestureDetector(
      onTap: onTapOverride ??
              () {
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
                  padding: const EdgeInsets.only(left: 4.0), // ← 텍스트만 오른쪽으로 1칸
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

  Widget _profileButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.66, // 화면의 2/3 너비
          margin: EdgeInsets.only(bottom: AppDimensions.normalize(10)), // 수직 간격 2배
          padding: EdgeInsets.symmetric(
            vertical: AppDimensions.normalize(6),
            horizontal: AppDimensions.normalize(6),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.normalize(4)),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft, // 왼쪽 정렬
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: AppDimensions.normalize(7.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.66, // 2/3 너비
          margin: EdgeInsets.only(bottom: AppDimensions.normalize(10)), // 간격 2배
          padding: EdgeInsets.symmetric(
            vertical: AppDimensions.normalize(6),
            horizontal: AppDimensions.normalize(6),
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimensions.normalize(4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppDimensions.normalize(7.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppDimensions.normalize(4)),
              Icon(icon, color: Colors.white, size: AppDimensions.normalize(8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconRow(
      BuildContext context,
      String title,
      String iconPath,
      String? route,
      Widget arrow, {
        Color? iconColor,
      }) {
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
              padding: const EdgeInsets.only(left: 2.0), // 🔹 여기가 핵심
              child: Row(
                children: [
                  SvgPicture.asset(
                    iconPath,
                    height: AppDimensions.normalize(14),
                    color: iconColor,
                  ),
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

  Widget _customIconRow(IconData icon, String label, SvgPicture arrow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.CommonCyan),
            Space.xf(),
            Text(label, style: AppText.b1b),
          ],
        ),
        arrow,
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppText.h3b?.copyWith(color: AppColors.CommonCyan));
  }

  Widget _notificationSwitch() {
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
        SizedBox(
          height: AppDimensions.normalize(10),
          child: Switch(
            value: true,
            onChanged: null,
            activeTrackColor: AppColors.CommonCyan,
            thumbColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ],
    );
  }
}

Widget unLoggedProfileContainer(BuildContext context) {
  return Column(
    children: [
      CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, size: 40, color: Colors.white),
      ),
      SizedBox(height: 12),
      Text(
        "로그인이 필요합니다.",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 12),
      ElevatedButton(
        onPressed: () {
          // 로그인 화면으로 이동
          Navigator.pushNamed(context, '/login');
        },
        child: Text("로그인하러 가기"),
      ),
    ],
  );
}
