import 'package:flutter/material.dart';
import 'package:greon/domain/entities/delivery/delivery_info.dart';
import 'package:greon/presentation/screens/add_edit_address.dart';
import 'package:greon/presentation/screens/ads.dart';
import 'package:greon/presentation/screens/app_info.dart';
import 'package:greon/presentation/screens/cart.dart';
import 'package:greon/presentation/screens/checkout.dart';
import 'package:greon/presentation/screens/contact.dart';
import 'package:greon/presentation/screens/filter.dart';
import 'package:greon/presentation/screens/login.dart';
import 'package:greon/presentation/screens/notifications.dart';
import 'package:greon/presentation/screens/order_failure.dart';
import 'package:greon/presentation/screens/order_success.dart';
import 'package:greon/presentation/screens/orders.dart';
import 'package:greon/presentation/screens/product_details.dart';
import 'package:greon/presentation/screens/root.dart';
import 'package:greon/presentation/screens/search.dart';
import 'package:greon/presentation/screens/signup.dart';
import 'package:greon/presentation/screens/splash.dart';
import 'package:greon/presentation/screens/wishlist.dart';

import '../../data/models/model/PostModel.dart';
import '../../domain/entities/cart/cart_item.dart';
import '../../domain/entities/product/product.dart';
import '../../presentation/screens/my_plants_screen.dart';
import '../../presentation/screens/post.dart';
import '../../presentation/screens/post_detail.dart';
import '../../presentation/screens/register_plant.dart';
import '../../presentation/screens/addresses.dart';

import '../../presentation/screens/write_screen.dart';
import '../error/exceptions.dart';

sealed class AppRouter {
  static const String splash = '/';
  static const String ads = '/ads';
  static const String root = '/root';
  static const String productDetails = '/product-details';
  static const String search = '/search';
  static const String filter = '/filter';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String addresses = '/addresses';
  static const String addadress = '/addadress';
  static const String checkout = '/checkout';
  static const String contact = '/contact';
  static const String appinfo = '/appinfo';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String ordersuccess = '/ordersuccess';
  static const String orderfailure = '/orderfailure';
  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String registerPlant = '/register-plant';
  static const String myPlants = '/my-plants';

  // 게시판 관련 경로 추가
  static const String bulletinBoard = '/bulletin-board';
  static const String writePost = '/write-post';
  static const String postDetail = '/post-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case ads:
        return MaterialPageRoute(builder: (_) => const AdsScreen());
      case root:
        return MaterialPageRoute(builder: (_) => const RootScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case filter:
        return MaterialPageRoute(builder: (_) => const FilterScreen());
      case productDetails:
        ProductEntity product = routeSettings.arguments as ProductEntity;
        return MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product));
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case contact:
        return MaterialPageRoute(builder: (_) => ContactScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case addresses:
        return MaterialPageRoute(builder: (_) => const AddressesScreen());
      case addadress:
        DeliveryInfo? deliveryInfo = routeSettings.arguments as DeliveryInfo?;
        return MaterialPageRoute(
            builder: (_) => AddAddressScreen(
              deliveryInfo: deliveryInfo,
            ));
      case checkout:
        List<CartItem> items = routeSettings.arguments as List<CartItem>;
        return MaterialPageRoute(
            builder: (_) => CheckOutScreen(
              items: items,
            ));
      case appinfo:
        String screenTitle = routeSettings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => AppInfoScreen(
              screenTitle: screenTitle,
            ));
      case wishlist:
        return MaterialPageRoute(builder: (_) => const WishListScreen());
      case ordersuccess:
        return MaterialPageRoute(builder: (_) => const OrderSuccessScreen());
      case orderfailure:
        return MaterialPageRoute(builder: (_) => const OrderFailureScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case registerPlant:
        return MaterialPageRoute(builder: (_) => RegisterPlant());
      case myPlants:
        return MaterialPageRoute(builder: (_) => const MyPlantsScreen());

    // 게시판 관련 라우팅 추가
      case bulletinBoard:
        return MaterialPageRoute(builder: (_) => const BulletinBoardScreen());
      case writePost:
        return MaterialPageRoute(builder: (_) => const WritePostScreen());
      case postDetail:
        final post = routeSettings.arguments as PostModel;
        return MaterialPageRoute(builder: (_) => PostDetailScreen(post: post));

      default:
        throw const RouteException('Route not found!');
    }
  }
}
