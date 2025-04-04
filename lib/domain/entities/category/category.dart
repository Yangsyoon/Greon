import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Category 모델
class Category {
  final String name;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Category({
    required this.name,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String? ?? '기본 카테고리',
      image: json['image'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// 🔹 **기본 카테고리 반환**
  static Category defaultCategory() {
    return Category(
      name: '기본 카테고리',
      image: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
    );
  }

  /// 🔹 Firestore DocumentReference에서 Category 객체 변환
  static Future<Category> fromDocumentReference(DocumentReference ref) async {
    try {
      final snapshot = await ref.get();
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return defaultCategory();

      return Category(
        name: data["name"] ?? '기본 카테고리',
        image: data["image"] ?? '',
        createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data["updatedAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data["isActive"] ?? false,
      );
    } catch (error) {
      print('🔥 Category.fromDocumentReference 에러: $error');
      return defaultCategory();
    }
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "image": image,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "isActive": isActive,
  };
}


