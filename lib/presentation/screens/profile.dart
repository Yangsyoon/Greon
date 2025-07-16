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

  Widget _buildLoggedInSection(BuildContext context, SvgPicture arrowForward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _profileButton(context, "내 식물 보기", AppColors.CommonCyan, () {
          Navigator.of(context).pushNamed(AppRouter.myPlants);
        }),
        _iconButton(context, "내 식물 추가", Icons.add, AppColors.CommonCyan, () {
          Navigator.of(context).pushNamed(AppRouter.registerPlant);
        }),
        _iconButton(context, "식물 캘린더", Icons.calendar_month, Colors.teal, () {
          Navigator.of(context).pushNamed(AppRouter.calendar);
        }),
        // 👉 위시리스트 버튼 추가
        _iconButton(
          context,
          "위시리스트",
          Icons.favorite,
          Colors.pink,
              () {
            Navigator.of(context).pushNamed(AppRouter.wishlist);
          },
        ),
        Space.yf(1.3),
        _sectionTitle("MY ACCOUNT"),
        _iconRow(context, "My Orders", AppAssets.Archive, AppRouter.orders, arrowForward),
        _iconRow(context, "Address Book", AppAssets.Marker, AppRouter.addresses, arrowForward),
        _iconRow(context, "Edit Account", AppAssets.Profile, null, arrowForward, iconColor: AppColors.CommonCyan),
        _iconRow(context, "Change Password", AppAssets.Lock, null, arrowForward),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserInfoInputPage()));
          },
          child: _customIconRow(Icons.info_outline, "회원 정보 입력", arrowForward),
        ),
        Space.yf(1.9),
        _sectionTitle("SETTINGS"),
        _notificationSwitch(),
        Space.yf(2.9),
        Center(child: Text("V.1.0", style: AppText.b1b)),
        Space.yf(.3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.Whats, height: AppDimensions.normalize(15)),
            SvgPicture.asset(AppAssets.Noti, height: AppDimensions.normalize(15)),
            SvgPicture.asset(AppAssets.Music, height: AppDimensions.normalize(15)),
          ],
        ),
        Space.yf(1.3),
      ],
    );
  }

  Widget _profileButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimensions.normalize(5)),
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.normalize(4),
          horizontal: AppDimensions.normalize(20),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.normalize(5)),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: AppDimensions.normalize(8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _iconButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimensions.normalize(5)),
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.normalize(4),
          horizontal: AppDimensions.normalize(20),
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.normalize(5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: AppDimensions.normalize(8)),
            SizedBox(width: AppDimensions.normalize(3)),
            Text(label, style: AppText.b1?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _iconRow(BuildContext context, String title, String iconAsset, String? route, Widget arrow, {Color? iconColor}) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.normalize(5)), // ← 여기!
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  colorFilter: iconColor != null
                      ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                      : null,
                ),
                Space.xf(),
                Text(title, style: AppText.b1b),
              ],
            ),
            arrow
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
            Text("Notifications", style: AppText.b1b),
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
