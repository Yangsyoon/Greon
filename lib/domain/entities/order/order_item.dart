import 'package:equatable/equatable.dart';

import '../product/product.dart';

class OrderItem extends Equatable {
  final String id;
  final ProductEntity product;
  final num price;
  final num quantity;

  const OrderItem({
    required this.id,
    required this.product,
    required this.price,
    required this.quantity,
  });

  @override
  List<Object> get props => [
    id,
  ];
}
