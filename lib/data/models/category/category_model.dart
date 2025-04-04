import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../domain/entities/category/category.dart';

List<CategoryModel> categoryModelListFromRemoteJson(String str) =>
    List<CategoryModel>.from(
        json.decode(str)['data'].map((x) => CategoryModel.fromJson(x)));

List<CategoryModel> categoryModelListFromLocalJson(String str) =>
    List<CategoryModel>.from(
        json.decode(str).map((x) => CategoryModel.fromJson(x)));

String categoryModelListToJson(List<CategoryModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CategoryModel extends Category {
  CategoryModel({
    required String name,
    required String image,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isActive,
  }) : super(
    name: name,
    image: image,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isActive: isActive,
  );

  // JSON에서 CategoryModel 객체로 변환
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    name: json["name"],
    image: json["image"] ?? "", // 기본값
    createdAt: (json["createdAt"] as Timestamp).toDate(),
    updatedAt: (json["updatedAt"] as Timestamp).toDate(),
    isActive: json["isActive"] ?? true,
  );

  // CategoryModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => {
    "name": name,
    "image": image,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "isActive": isActive,
  };

  // Category를 CategoryModel로 변환
  factory CategoryModel.fromEntity(Category entity) => CategoryModel(
    name: entity.name,
    image: entity.image,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    isActive: entity.isActive,
  );

  // Firestore의 DocumentReference로부터 CategoryModel 객체로 변환 (비동기 처리 필요)
  static Future<CategoryModel> fromDocumentReference(DocumentReference reference) async {
    try {
      final doc = await reference.get();
      if (!doc.exists) throw Exception("해당 카테고리 문서가 존재하지 않습니다.");

      final rawData = doc.data();

      // 🛑 Firestore 데이터가 Map<String, dynamic> 형태인지 확인
      if (rawData is! Map<String, dynamic>) {
        throw Exception("Firestore 데이터가 Map<String, dynamic>이 아님: ${rawData.runtimeType}");
      }

      final data = rawData as Map<String, dynamic>;

      return CategoryModel(
        name: data["name"] ?? '기본 카테고리명',
        image: data["image"] ?? '',
        createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data["updatedAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data["isActive"] ?? true,
      );
    } catch (e) {
      debugPrint("🔥 CategoryModel 변환 오류: $e");
      return CategoryModel(
        name: '오류 발생',
        image: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
      );
    }
  }
}


