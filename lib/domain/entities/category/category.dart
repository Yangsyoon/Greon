import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  /// 날짜 변환 헬퍼 함수
  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String? ?? '기본 카테고리',
      image: json['image'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// 기본 카테고리 반환
  static Category defaultCategory() {
    final now = DateTime.now();
    return Category(
      name: '기본 카테고리',
      image: '',
      createdAt: now,
      updatedAt: now,
      isActive: false,
    );
  }

  /// Firestore DocumentReference에서 Category 객체 변환
  static Future<Category> fromDocumentReference(DocumentReference ref) async {
    try {
      final snapshot = await ref.get();
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return defaultCategory();

      return Category(
        name: data["name"] ?? '기본 카테고리',
        image: data["image"] ?? '',
        createdAt: _parseDate(data["createdAt"]),
        updatedAt: _parseDate(data["updatedAt"]),
        isActive: data["isActive"] ?? false,
      );
    } catch (error) {
      debugPrint('🔥 Category.fromDocumentReference 에러: $error');
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
