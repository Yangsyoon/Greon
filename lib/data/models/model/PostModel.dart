// lib/data/models/model/PostModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String content;
  final String uid;
  final DateTime createdAt;
  final int commentsCount;

  PostModel({
    required this.uid,
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.commentsCount,
  });

  factory PostModel.fromDocument(Map<String, dynamic> doc, String id) {
    return PostModel(
      id: id,
      title: doc['title'] ?? '',
      content: doc['content'] ?? '',
      uid: doc['uid'] ?? '',
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      commentsCount: doc['commentsCount'] ?? 0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentsCount': commentsCount,
    };
  }

}
