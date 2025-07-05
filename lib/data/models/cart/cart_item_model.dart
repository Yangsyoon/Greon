import 'dart:convert';

import '../../../domain/entities/cart/cart_item.dart';
import '../../../domain/entities/product/product.dart';
import '../product/product_model.dart';

List<CartItemModel> cartItemModelListFromLocalJson(String str) =>
    List<CartItemModel>.from(
        json.decode(str).map((x) => CartItemModel.fromJson(x)));

List<CartItemModel> cartItemModelListFromRemoteJson(String str) =>
    List<CartItemModel>.from(
        json.decode(str)["data"].map((x) => CartItemModel.fromJson(x)));

List<CartItemModel> cartItemModelFromJson(String str) =>
    List<CartItemModel>.from(
        json.decode(str).map((x) => CartItemModel.fromJson(x)));

String cartItemModelToJson(List<CartItemModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CartItemModel extends CartItem {
  CartItemModel({
    String? id,
    required ProductModel product,
    required int price,
  }) : super(
    id: id,
    product: product.toEntity(),
    price: price,
  );

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json["_id"],
      product: ProductModel.fromJson(json["product"]),
      price: json["price"],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "product": ProductModel.fromEntity(product).toJson(),
    "price": price,
  };

  Map<String, dynamic> toBodyJson() => {
    "_id": id,
    "product": product.id,
    "price": price,
  };

  factory CartItemModel.fromParent(CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      product: ProductModel.fromEntity(cartItem.product),
      price: cartItem.price,
    );
  }
}
