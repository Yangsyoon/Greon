// lib/di/di.dart

import 'package:get_it/get_it.dart';
import 'package:greon/di/cubits.dart';
import 'package:greon/di/order.dart';
import 'package:greon/di/product.dart';
import 'package:greon/di/user.dart';
import 'cart.dart';
import 'category.dart';
import 'common.dart';
import 'delivery.dart';
import 'post.dart'; // 👈 1. 새로 만든 post.dart 파일 import

final sl = GetIt.instance;

Future<void> init() async {
  // Register features
  registerCategoryFeature();
  registerProductFeature();
  registerUserFeature();
  registerDeliveryInfoFeature();
  registerCartFeature();
  registerOrderFeature();
  registerPostFeature(); // 👈 2. Post 기능 등록 함수 호출

  // Register Cubits
  registerCubits();

  // Register common dependencies
  await registerCommonDependencies();
}