import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../domain/entities/category/category.dart';
import '../../../domain/entities/product/product.dart'; // ProductEntity 임포트

class ProductModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<Category> categories;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categories,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ProductModel.errorModel([String? docId]) {
    return ProductModel(
      id: docId ?? "error",
      name: "오류 발생",
      description: "데이터 변환 중 오류 발생",
      price: 0,
      categories: [],
      images: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
    );
  }

  /// Entity 변환 메서드
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      categories: categories,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Firestore에서 데이터 변환
  static Future<ProductModel> fromDocumentAsync(DocumentSnapshot doc) async {
    try {
      final rawData = doc.data();

      if (rawData is! Map<String, dynamic>) {
        throw Exception("Firestore 데이터가 Map<String, dynamic>이 아님: ${rawData.runtimeType}");
      }

      final data = rawData as Map<String, dynamic>;

      // categories 변환 (DocumentReference → Category 객체 변환)
      List<Category> categories = await Future.wait(
        (data["categories"] as List<dynamic>? ?? []).map((e) async {
          try {
            if (e is DocumentReference || e.runtimeType.toString() == "_JsonDocumentReference") {
              final snapshot = await e.get();
              final r = snapshot.data();
              if (r is! Map<String, dynamic>) return Category.defaultCategory();
              return Category(
                name: r["name"] ?? "기본 카테고리",
                image: r["image"] ?? "",
                createdAt: (r["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (r["updatedAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
                isActive: r["isActive"] ?? false,
              );
            } else if (e is Map<String, dynamic>) {
              return Category.fromJson(e);
            }
          } catch (error) {
            debugPrint("🔥 categories 변환 오류: $error");
          }
          return Category.defaultCategory();
        }).toList(),
      );

      return ProductModel(
        id: doc.id,
        name: data["name"] ?? "상품명 없음",
        description: data["description"] ?? "설명 없음",
        price: data["price"] ?? 0,
        categories: categories,
        images: (data["images"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data["updatedAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data["isActive"] ?? false,
      );
    } catch (e, stackTrace) {
      debugPrint("🔥 ProductModel 변환 오류: $e");
      debugPrint("📌 StackTrace: $stackTrace");
      return ProductModel.errorModel(doc.id);
    }
  }

  /// JSON 변환 (Firestore 저장용)
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "price": price,
    "categories": categories.map((e) => e.toJson()).toList(),
    "images": images,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "isActive": isActive,
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"] ?? "",
      name: json["name"] ?? "상품명 없음",
      description: json["description"] ?? "설명 없음",
      price: json["price"] ?? 0,
      categories: (json["categories"] as List<dynamic>? ?? [])
          .map((e) => Category.fromJson(e))
          .toList(),
      images: List<String>.from(json["images"] ?? []),
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? "") ?? DateTime.now(),
      isActive: json["isActive"] ?? false,
    );
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      categories: entity.categories,
      images: entity.images,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }
}
