import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/model/PostModel.dart';

class PostRepository {
  final FirebaseFirestore firestore;

  PostRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<PostModel>> fetchPosts() async {
    final snapshot = await firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PostModel.fromDocument(doc.data(), doc.id))
        .toList();
  }

  Future<void> addPost(PostModel post) async {
    final data = post.toJson();
    data['commentsCount'] = 0;
    await firestore.collection('posts').add(data);
  }
}
