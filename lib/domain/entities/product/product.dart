import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../category/category.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<Category> categories;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ProductEntity({
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

  factory ProductEntity.fromMap(Map<String, dynamic> map, {required String docId}) {
    return ProductEntity(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0) is int ? map['price'] : int.tryParse(map['price'].toString()) ?? 0,
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categories': categories.map((c) => c.toJson()).toList(),
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  static Future<ProductEntity> fromMapAsync(Map<String, dynamic> map, {required String docId}) async {
    List<dynamic> rawCategories = map['categories'] ?? [];

    List<Category> categories = [];
    for (var item in rawCategories) {
      if (item is DocumentReference) {
        final snapshot = await item.get();
        final categoryMap = snapshot.data() as Map<String, dynamic>;
        categories.add(Category.fromJson(categoryMap));
      } else if (item is Map<String, dynamic>) {
        categories.add(Category.fromJson(item));
      }
    }

    return ProductEntity(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0) is int ? map['price'] : int.tryParse(map['price'].toString()) ?? 0,
      categories: categories,
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id];
}
