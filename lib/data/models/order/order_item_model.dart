import '../../../domain/entities/order/order_item.dart';
import '../product/price_tag_model.dart';
import '../product/product_model.dart';

class OrderItemModel extends OrderItem {
  OrderItemModel({
    required String id,
    required ProductModel product,
    required PriceTagModel priceTag,
    required num price,
    required num quantity,
  }) : super(
    id: id,
    product: product.toEntity(),
    priceTag: priceTag,
    price: price,
    quantity: quantity,
  );

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json["_id"],
      product: ProductModel.fromJson(json["product"]),
      priceTag: PriceTagModel.fromJson(json["priceTag"]),
      price: json["price"],
      quantity: json["quantity"],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "product": ProductModel.fromEntity(product).toJson(),
    "priceTag": priceTag.toJson(),
    "price": price,
    "quantity": quantity,
  };

  Map<String, dynamic> toJsonBody() => {
    "_id": id,
    "product": product.id,
    "priceTag": priceTag.id,
    "price": price,
    "quantity": quantity,
  };

  factory OrderItemModel.fromEntity(OrderItem entity) => OrderItemModel(
    id: entity.id,
    product: ProductModel.fromEntity(entity.product),
    priceTag: PriceTagModel.fromEntity(entity.priceTag),
    price: entity.price,
    quantity: entity.quantity,
  );
}
