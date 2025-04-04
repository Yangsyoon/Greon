import 'package:cloud_firestore/cloud_firestore.dart';

class PriceTag {
  final String id;
  final String name;
  final num price;

  PriceTag({
    required this.id,
    required this.name,
    required this.price,
  });

  factory PriceTag.fromJson(Map<String, dynamic> json) {
    return PriceTag(
      id: json['id'] as String? ?? 'default_id',
      name: json['name'] as String? ?? '기본 가격 태그',
      price: json['price'] as num? ?? 0,
    );
  }

  /// 🔹 **기본 PriceTag 반환**
  static PriceTag defaultTag() {
    return PriceTag(
      id: 'default_id',
      name: '기본 가격 태그',
      price: 0,
    );
  }

  /// 🔹 Firestore DocumentReference에서 PriceTag 객체 변환
  static Future<PriceTag> fromDocumentReference(DocumentReference ref) async {
    try {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) return defaultTag();

      return PriceTag(
        id: doc.id,
        name: data['name'] ?? '기본 가격 태그',
        price: data['price'] ?? 0,
      );
    } catch (error) {
      print('🔥 PriceTag.fromDocumentReference 에러: $error');
      return defaultTag();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}
