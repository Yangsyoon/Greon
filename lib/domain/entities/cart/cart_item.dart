import 'package:equatable/equatable.dart';

import '../product/product.dart';

class CartItem extends Equatable {
  final String? id;
  final ProductEntity product;
  final int price;

  const CartItem({this.id, required this.product, required this.price});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(), // ProductEntity도 toJson 있어야 함
      'price': price,
    };
  }

  @override
  List<Object?> get props => [id, product, price];
}

