import 'package:get_it/get_it.dart';
import 'package:greon/di/cubits.dart';
import 'package:greon/di/order.dart';
import 'package:greon/di/product.dart';
import 'package:greon/di/user.dart';
import 'cart.dart';
import 'category.dart';
import 'common.dart';
import 'delivery.dart';

final sl = GetIt.instance;

// Main Initialization
Future<void> init({required String userId}) async {
  // Register features
  registerCategoryFeature();
  registerProductFeature();
  registerUserFeature();
  registerDeliveryInfoFeature();
  registerCartFeature();
  registerOrderFeature();

  // Register Cubits (userId 필요)
  registerCubits(userId: userId);

  // Register common dependencies
  await registerCommonDependencies();
}

