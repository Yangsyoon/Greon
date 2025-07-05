import 'package:equatable/equatable.dart';

import '../product/product.dart';

class CartItem extends Equatable {
  final String? id;
  final ProductEntity product;
  final int price;

  const CartItem({this.id, required this.product, required this.price});

  @override
  List<Object?> get props => [id];
}
