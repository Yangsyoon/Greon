import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../product/product.dart';

class CartItem extends Equatable {
  final String? id;
  final ProductEntity product;
  final int price;
  final int quantity;

  const CartItem({
    this.id,
    required this.product,
    required this.price,
    required this.quantity,
  });

  /// Firestore 저장용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(), // ProductEntity에 toJson 필요
      'price': price,
      'productId': product.id,
      'quantity': quantity,
    };
  }

  /// Firestore 읽기용
  factory CartItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CartItem(
      id: doc.id,
      product: ProductEntity.fromMap(data['product'], docId: data['product']['id']),
      price: data['price'],
      quantity: data['quantity'] ?? 1,
    );
  }


  @override
  List<Object?> get props => [id, product, price, quantity];
}
