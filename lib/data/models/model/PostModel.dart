import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String content;
  final String uid;
  final DateTime createdAt;
  final int commentsCount;
  int likesCount;
  final String? imageUrl;
  final String category;
  final String? authorNickname;

  PostModel({
    required this.uid,
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.commentsCount,
    required this.likesCount,
    this.imageUrl,
    required this.category,
    this.authorNickname,
  });

  // factory PostModel.fromDocument(Map<String, dynamic> doc, String id) {
  //   return PostModel(
  //     id: id,
  //     title: doc['title'] ?? '',
  //     content: doc['content'] ?? '',
  //     uid: doc['uid'] ?? '',
  //     createdAt: (doc['createdAt'] as Timestamp).toDate(),
  //     commentsCount: doc['commentsCount'] ?? 0,
  //     likesCount: doc['likesCount'] ?? 0,
  //     imageUrl: doc['imageUrl'] as String?, // 안전하게 캐스팅
  //     category: doc['category'] ?? '',
  //   );
  // }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      if (imageUrl != null) 'imageUrl': imageUrl,  // null이면 필드 아예 안 넣음
      'category': category,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: '', // 이건 나중에 doc.id로 외부에서 .copyWith(id: ...)로 설정해줘야 함
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      uid: map['uid'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      commentsCount: map['commentsCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      imageUrl: map['imageUrl'] as String?,
      category: map['category'] ?? '',
    );
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? content,
    String? uid,
    DateTime? createdAt,
    int? commentsCount,
    int? likesCount,
    String? imageUrl,
    String? category,
    String? authorNickname,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      authorNickname: authorNickname ?? this.authorNickname,
    );
  }

}
