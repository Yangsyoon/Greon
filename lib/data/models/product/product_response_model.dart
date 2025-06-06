import '../../../domain/entities/product/pagination_meta_data.dart';
import '../../../domain/entities/product/product.dart';
import '../../../domain/entities/product/product_response.dart';
import 'pagination_data_model.dart';
import 'product_model.dart';
import 'dart:convert';

ProductResponseModel productResponseModelFromJson(String str) =>
    ProductResponseModel.fromJson(json.decode(str));

String productResponseModelToJson(ProductResponseModel data) =>
    json.encode(data.toJson());

class ProductResponseModel extends ProductResponse {
  ProductResponseModel({
    required PaginationMetaData meta,
    required List<ProductModel> data,
  }) : super(
    products: data.map((product) => product.toEntity()).toList(),
    paginationMetaData: meta,
  );

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) =>
      ProductResponseModel(
        meta: PaginationMetaDataModel.fromJson(json["meta"]),
        data: List<ProductModel>.from(
            json["data"].map((x) => ProductModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "meta": PaginationMetaDataModel.fromEntity(paginationMetaData).toJson(),
    "data": products.map((x) => ProductModel.fromEntity(x).toJson()).toList(),
  };

}

