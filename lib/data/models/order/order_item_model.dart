import '../../../domain/entities/order/order_item.dart';
import '../product/product_model.dart';

class OrderItemModel extends OrderItem {
  OrderItemModel({
    required String id,
    required ProductModel product,
    required num price,
    required num quantity,
  }) : super(
    id: id,
    product: product.toEntity(),
    price: price,
    quantity: quantity,
  );

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json["_id"],
      product: ProductModel.fromJson(json["product"]),
      price: json["price"],
      quantity: json["quantity"],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "product": ProductModel.fromEntity(product).toJson(),
    "price": price,
    "quantity": quantity,
  };

  Map<String, dynamic> toJsonBody() => {
    "_id": id,
    "product": product.id,
    "price": price,
    "quantity": quantity,
  };

  factory OrderItemModel.fromEntity(OrderItem entity) => OrderItemModel(
    id: entity.id,
    product: ProductModel.fromEntity(entity.product),
    price: entity.price,
    quantity: entity.quantity,
  );
}
