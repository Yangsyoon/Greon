import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/presentation/screens/post/post.dart';
import 'package:greon/presentation/screens/product/products_list.dart';
import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../core/enums/enums.dart';
import 'home.dart';
import 'my_plants_screen.dart';
import 'calendar_screen.dart';
import 'settings_page.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    final tabs =  [
      HomeScreen(),                  // 홈
      BulletinBoardScreen(),         // 게시판
      MyPlantsScreen(),              // 내식물
      ProductsListScreen(),          // 쇼핑
      CalendarScreen(userId: userId),  // 캘린더, userId 전달
      SettingsPage(),                // 개인페이지
    ];

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        final activeTab = state.tab;
        final selectedIndex = activeTab.index;

        print("탭 변경 감지: $selectedIndex");

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            // ✅ onTap에서 열거형 값을 업데이트합니다.
            onTap: (i) => context.read<NavigationCubit>().updateTab(NavigationTab.values[i]),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black26,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
              BottomNavigationBarItem(icon: Icon(Icons.forum), label: "게시판"),
              BottomNavigationBarItem(icon: Icon(Icons.eco), label: "내식물"),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "쇼핑"),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "캘린더"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "개인페이지"),
            ],
          ),
        );
      },
    );
  }
}
