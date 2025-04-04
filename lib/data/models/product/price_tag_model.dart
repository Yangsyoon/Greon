
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../domain/entities/product/price_tag.dart';

class PriceTagModel extends PriceTag {
  PriceTagModel({
    required String id,
    required String name,
    required num price,
  }) : super(
    id: id,
    name: name,
    price: price,
  );

  /// **Firestore에서 가져올 때 `DocumentReference` 처리**
  static Future<PriceTagModel> fromDocumentReference(DocumentReference reference) async {
    try {
      final doc = await reference.get();
      if (!doc.exists) throw Exception("해당 PriceTag 문서가 존재하지 않습니다.");
      if (doc is! Map<String, dynamic>) {
        throw Exception("Firestore 데이터가 Map<String, dynamic>이 아님: ${doc.runtimeType}");
      }
      final data = doc.data() as Map<String, dynamic>? ?? {};

      return PriceTagModel(
        id: doc.id,
        name: data["name"] ?? "기본 가격 태그",
        price: data["price"] ?? 0,
      );
    } catch (e) {
      debugPrint("🔥 PriceTagModel 변환 오류: $e");
      return PriceTagModel(
        id: "오류",
        name: "데이터 오류",
        price: 0,
      );
    }
  }

  /// **JSON에서 객체 변환**
  factory PriceTagModel.fromJson(Map<String, dynamic> json) => PriceTagModel(
    id: json["_id"] ?? "",
    name: json["name"] ?? "기본 가격 태그",
    price: json["price"] ?? 0,
  );

  /// **객체를 JSON으로 변환**
  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "price": price,
  };

  /// **PriceTag 엔티티에서 변환**
  factory PriceTagModel.fromEntity(PriceTag entity) => PriceTagModel(
    id: entity.id,
    name: entity.name,
    price: entity.price,
  );

  // 추가: toString() 메서드 재정의 (디버깅 용이성 향상)
  @override
  String toString() {
    return 'PriceTagModel(id: $id, name: $name, price: $price)';
  }
}
