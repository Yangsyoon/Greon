import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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
    required int quantity,
  }) : super(
    id: id,
    product: product.toEntity(),
    price: price,
    quantity: quantity,
  );

  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      id: entity.id,
      product: ProductModel.fromEntity(entity.product), // ProductModel도 fromEntity 필요
      price: entity.price,
      quantity: entity.quantity,
    );
  }

  /// ✅ copyWith에 quantity 추가
  CartItemModel copyWith({
    String? id,
    ProductModel? product,
    int? price,
    int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? ProductModel.fromEntity(this.product),
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final dynamic productData = json["product"];

    late final ProductModel productModel;

    if (productData is Map<String, dynamic>) {
      productModel = ProductModel.fromJson(productData);
    } else if (productData is String) {
      // 최소 정보로 생성
      productModel = ProductModel(
        id: productData,
        name: '',
        price: 0,
        description: '',
        categories: [],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    } else {
      throw Exception("Invalid product format in CartItemModel.fromJson");
    }

    return CartItemModel(
      id: json["_id"],
      product: productModel,
      price: json["price"] is int ? json["price"] : int.tryParse('${json["price"]}') ?? 0,
      quantity: json["quantity"] is int ? json["quantity"] : int.tryParse('${json["quantity"]}') ?? 1,
    );
  }


  /// ✅ toJson에 quantity 추가
  Map<String, dynamic> toJson() =>
      {
        "_id": id,
        "product": ProductModel.fromEntity(product).toJson(),
        "productId": product.id,
        "price": price,
        "quantity": quantity, // ✅ 추가
      };

  /// 부모 엔티티에서 모델로 변환
  factory CartItemModel.fromParent(CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      product: ProductModel.fromEntity(cartItem.product),
      price: cartItem.price,
      quantity: cartItem.quantity ?? 1, // ✅ 추가
    );
  }

  factory CartItemModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Cart document is null');
    }

    final dynamic productData = data['product'];

    // 문자열이면 비정상 케이스 → 빈 productModel로 대체 (에러 방지)
    final ProductModel productModel = (productData is Map<String, dynamic>)
        ? ProductModel.fromJson(productData)
        : ProductModel(
      id: '',
      name: '',
      price: 0,
      description: '',
      categories: [],
      images: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
    );

    return CartItemModel(
      id: doc.id,
      product: data['product'] is Map<String, dynamic>
          ? ProductModel.fromJson(data['product'])
          : ProductModel.errorModel(),
      price: data['price'] is int
          ? data['price']
          : int.tryParse('${data['price']}') ?? 0,
      quantity: data['quantity'] is int
          ? data['quantity']
          : int.tryParse('${data['quantity']}') ?? 1,
    );
  }

}


  extension CartItemModelX on CartItemModel {
    CartItem toDomain() {
      return CartItem(
        id: id,
        product: product is ProductModel
            ? (product as ProductModel).toEntity()
            : product,
        price: price,
        quantity: quantity ?? 1,
      );
    }
  }

extension CartItemModelXExtra on CartItemModel {
  String get productId => product.id;
}
