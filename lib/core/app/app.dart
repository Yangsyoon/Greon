import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/application/share_cubit/share_cubit.dart';

import 'package:greon/application/wishlist_cubit/wishlist_cubit.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/cart_bloc/cart_bloc.dart';
import '../../application/delivery_info_action_cubit/delivery_info_action_cubit.dart';
import '../../application/delivery_info_fetch_cubit/delivery_info_fetch_cubit.dart';
import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/notifications_cubit/notifications_cubit.dart';
import '../../application/order_add_cubit/order_add_cubit.dart';
import '../../application/order_fetch_cubit/order_fetch_cubit.dart';
import '../../application/products_bloc/product_bloc.dart';
import '../../application/user_bloc/user_bloc.dart';
import '../../data/models/product/filter_params_model.dart';
import '../../di/di.dart' as di;

import '../../application/categories_bloc/category_bloc.dart';

import '../router/app_router.dart';
import '../constant/colors.dart';
import '../constant/strings.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<NavigationCubit>()),
        BlocProvider(
          create: (context) => di.sl<WishlistCubit>()..loadWishlist(),
        ),
        BlocProvider(
          create: (context) =>
              di.sl<CategoryBloc>()..add(const GetCategories()),
        ),
        BlocProvider(
          create: (context) => di.sl<ProductBloc>()
            ..add(const GetProducts(FilterProductParams())),
        ),
        BlocProvider(
          create: (context) => di.sl<FilterCubit>(),
        ),
        BlocProvider(
          create: (context) => di.sl<UserBloc>()..add(CheckUser()),
        ),
        BlocProvider(
          create: (context) => di.sl<CartBloc>()..add(const GetCart()),
        ),
        BlocProvider(
          create: (context) => di.sl<DeliveryInfoActionCubit>(),
        ),
        BlocProvider(
          lazy: false,
          create: (context) =>
              di.sl<DeliveryInfoFetchCubit>()..fetchDeliveryInfo(),
        ),
        BlocProvider(
          create: (context) => di.sl<OrderFetchCubit>()..getOrders(),
        ),
        BlocProvider(
          create: (context) => di.sl<OrderAddCubit>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ShareCubit>(),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => di.sl<NotificationsCubit>()..init(),
        ),
      ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: appTitle,
          onGenerateRoute: AppRouter.onGenerateRoute,
          theme: ThemeData.light().copyWith(
            canvasColor: Colors.white,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              color: Colors.white,
              elevation: 0,
              toolbarHeight: 56,
              centerTitle: true,
              iconTheme: IconThemeData(
                color: Colors.black,
                size: 30,
              ),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                side: MaterialStateProperty.resolveWith<BorderSide?>(
                      (states) {
                    return BorderSide(color: Colors.black, width: 1);
                  },
                ),
                foregroundColor: MaterialStateProperty.all(Colors.black),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                side: MaterialStateProperty.all(
                  BorderSide(color: Colors.black, width: 1),
                ),
                foregroundColor: MaterialStateProperty.all(Colors.black),
              ),
            ),
            iconTheme: const IconThemeData(
              color: Colors.black,
              size: 30,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black54,
              selectedLabelStyle: TextStyle(color: Colors.black),
              unselectedLabelStyle: TextStyle(color: Colors.black54),
            ),
          ),
          initialRoute: AppRouter.splash,
        )

    );
  }
}
