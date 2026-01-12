import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/presentation/screens/my_plants_screen.dart';
import 'package:greon/presentation/screens/post/post.dart'; // 게시판
import 'package:greon/presentation/screens/home.dart';
import 'package:greon/presentation/screens/product/products_list.dart';
import 'package:greon/presentation/screens/profile.dart';
import 'package:greon/presentation/widgets/bottom_navbar.dart';

// [중요] 로그인 페이지 import를 꼭 추가해주세요! 경로가 다르면 수정해주세요.
// 예: import 'package:greon/presentation/screens/login_screen.dart';
import 'package:greon/presentation/screens/login.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../core/enums/enums.dart';
import 'calendar_screen.dart';
import 'login.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    App.init(context);
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    Future<bool> _onWillPop() async {
      return (await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("앱 종료", style: TextStyle(color: Colors.black)),
          content: const Text("정말 앱을 종료하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text("네", style: TextStyle(color: Colors.red)),
              onPressed: () => SystemNavigator.pop(),
            ),
            TextButton(
              child: const Text("아니오", style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      )) ?? false;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        bottomNavigationBar: const BottomNavigation(),
        body: Center(
          child: BlocBuilder<NavigationCubit, NavigationState>(
            builder: (context, state) {
              final activeTab = state.tab;
              switch (activeTab) {
                case NavigationTab.homeTab:
                  return const HomeScreen();
                case NavigationTab.boardTab:
                  return const BulletinBoardScreen();
                case NavigationTab.myPlantsTab:
                  return const MyPlantsScreen();
                case NavigationTab.shoppingTab:
                  return const ProductsListScreen();
                case NavigationTab.calendarTab:
                  return CalendarScreen(userId: userId ?? '');

              // ✅ [핵심 수정 부분] 개인페이지 탭
                case NavigationTab.profileTab:
                  return StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      // 1. 로그인 정보가 있으면 -> 개인 페이지 보여줌
                      if (snapshot.hasData) {
                        return const ProfileScreen();
                      }
                      // 2. 로그인 정보가 없으면 -> 로그인 페이지 보여줌
                      // 'LoginScreen'은 실제 로그인 화면 위젯 이름으로 맞춰주세요.
                      return const LoginScreen();
                    },
                  );

                default:
                  return const HomeScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}