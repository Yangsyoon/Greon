// lib/data/repositories/post_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_sources/remote/post_remote_data_source.dart';
import '../models/model/PostModel.dart'; // PostModel 파일의 실제 경로

// --- 인터페이스 (계약) ---
// PostRepository가 어떤 기능을 가져야 하는지 정의
abstract class PostRepository {
  Future<List<PostModel>> fetchPosts({String? category, String? sort});
  Future<void> addPost(PostModel post);
  Future<int> toggleLike(String postId, String userId);
}

// --- 구현 클래스 ---
// 위에서 정의한 기능을 실제로 수행하는 클래스 (이 부분이 없어서 오류 발생)
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final FirebaseFirestore firestore; // '좋아요' 기능을 위해 추가

  PostRepositoryImpl({
    required this.remoteDataSource,
    FirebaseFirestore? firestore, // firestore를 선택적으로 받음
  }) : this.firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<PostModel>> fetchPosts({String? category, String? sort}) async {
    // Repository는 직접 데이터를 가져오지 않고 DataSource에게 요청합니다.
    // 닉네임 조인 로직 등은 DataSource 또는 여기서 처리할 수 있습니다.
    // (이전 답변의 상세 로직 참고)
    return await remoteDataSource.getPosts();
  }

  @override
  Future<void> addPost(PostModel post) async {
    final data = post.toJson();
    data['commentsCount'] = 0;
    await firestore.collection('posts').add(data);
  }

  @override
  Future<int> toggleLike(String postId, String userId) async {
    final postRef = firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await postRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'uid': userId, 'createdAt': Timestamp.now()});
      await postRef.update({'likesCount': FieldValue.increment(1)});
    }
    final postSnapshot = await postRef.get();
    return postSnapshot.data()?['likesCount'] ?? 0;
  }
}