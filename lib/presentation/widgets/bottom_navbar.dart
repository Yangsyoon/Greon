// bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../configs/app_dimensions.dart';
import '../../configs/app_typography.dart';
import '../../core/constant/assets.dart';
import '../../core/enums/enums.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    double height = AppDimensions.normalize(10);
    double width = AppDimensions.normalize(10);
    EdgeInsets padding = EdgeInsets.only(bottom: AppDimensions.normalize(1.5));

    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        final activeTab = state.tab;
        return SafeArea(
          child: SizedBox(
            height: AppDimensions.normalize(27),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: activeTab.index,
              onTap: (index) {
                final newTab = NavigationTab.values[index];
                context.read<NavigationCubit>().updateTab(newTab);
              },
              items: <BottomNavigationBarItem>[
                // 홈
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Home,
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '홈',
                ),
                // 게시판
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Board,
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '게시판',
                ),
                // 내식물
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Plant, // 내식물 아이콘에 맞게 변경 필요
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '내식물',
                ),
                // 쇼핑
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Cart,
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '쇼핑',
                ),
                // 캘린더
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Calendar, // 캘린더 아이콘 이미지 경로
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '캘린더',
                ),
                // 개인페이지
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: padding,
                    child: SvgPicture.asset(
                      AppAssets.Profile,
                      height: height,
                      width: width,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        activeTab == NavigationTab.homeTab
                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor!
                            : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor!,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  label: '개인페이지',
                ),
              ],
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black26,
              iconSize: AppDimensions.normalize(12),
              selectedLabelStyle: AppText.b2b,
              unselectedLabelStyle: AppText.b2,
            ),
          ),
        );
      },
    );
  }
}
