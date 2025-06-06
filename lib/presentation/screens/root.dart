import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/presentation/screens/cart.dart';
import 'package:greon/presentation/screens/post.dart';
import 'package:greon/presentation/screens/home.dart';
import 'package:greon/presentation/screens/products_list.dart';
import 'package:greon/presentation/screens/profile.dart';
import 'package:greon/presentation/widgets/bottom_navbar.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../core/enums/enums.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    App.init(context);
    Future<bool> _onWillPop() async {
      return (await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "Exit Application",
                style: TextStyle(color: AppColors.CommonCyan),
              ),
              content: const Text(
                "Are You Sure?",
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    "Yes",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    "No",
                    style: TextStyle(color: AppColors.CommonCyan),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          )) ??
          false;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        bottomNavigationBar: const BottomNavigation(),
        body: Center(
          child: BlocBuilder<NavigationCubit, NavigationTab>(
            builder: (context, activeTab) {
              switch (activeTab) {
                case NavigationTab.homeTab:
                  return const HomeScreen();
                case NavigationTab.categoriesTab:
                  return const BulletinBoardScreen();
                case NavigationTab.productsTap:
                  return const ProductsListScreen();
                case NavigationTab.cartTab:
                  return const CartScreen();
                case NavigationTab.profileTab:
                  return const ProfileScreen();
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
