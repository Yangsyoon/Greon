import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String content;
  final String uid;
  final DateTime createdAt;
  final int commentsCount;
  final String? imageUrl;  // nullable 처리

  PostModel({
    required this.uid,
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.commentsCount,
    this.imageUrl,
  });

  factory PostModel.fromDocument(Map<String, dynamic> doc, String id) {
    return PostModel(
      id: id,
      title: doc['title'] ?? '',
      content: doc['content'] ?? '',
      uid: doc['uid'] ?? '',
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      commentsCount: doc['commentsCount'] ?? 0,
      imageUrl: doc['imageUrl'] as String?, // 안전하게 캐스팅
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentsCount': commentsCount,
      if (imageUrl != null) 'imageUrl': imageUrl,  // null이면 필드 아예 안 넣음
    };
  }
}
