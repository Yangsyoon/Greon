import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/application/post_bloc/post_event.dart';
import 'package:greon/application/post_bloc/post_state.dart';
import '../../data/models/model/PostModel.dart';
import '../../data/repositories/post_repository.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository postRepository;

  PostBloc(this.postRepository) : super(PostInitial()) {
    on<LoadPosts>((event, emit) async {
      emit(PostLoading());
      try {
        Query query = FirebaseFirestore.instance.collection('posts');

        if (event.category != null) {
          query = query.where('category', isEqualTo: event.category);
        }

        query = query.orderBy('createdAt', descending: true);

        final snapshot = await query.get();

        final posts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PostModel.fromMap(data).copyWith(id: doc.id);
        }).toList();

        List<PostModel> sortedPosts = List.from(posts);
        if (event.sort == '최신순') {
          sortedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else if (event.sort == '추천순') {
          sortedPosts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        }

        emit(PostLoaded(sortedPosts));
      } catch (e) {
        emit(PostError());
      }
    });

    on<ToggleLikePost>((event, emit) async {
      final post = event.post;
      final userId = event.userId;

      final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
      final likeRef = postRef.collection('likes').doc(userId);

      final isLiked = (await likeRef.get()).exists;

      try {
        if (isLiked) {
          await likeRef.delete();
          await postRef.update({'likesCount': FieldValue.increment(-1)});
        } else {
          await likeRef.set({'uid': userId, 'createdAt': Timestamp.now()});
          await postRef.update({'likesCount': FieldValue.increment(1)});
        }

        // 로컬 상태 업데이트
        if (state is PostLoaded) {
          final posts = (state as PostLoaded).posts.map((p) {
            if (p.id == post.id) {
              final newLikes = isLiked ? (p.likesCount! - 1) : (p.likesCount! + 1);
              return p.copyWith(likesCount: newLikes);
            }
            return p;
          }).toList();

          emit(PostLoaded(posts));
        }
      } catch (e) {
        // 실패 시 무시 또는 에러 처리
      }
    });
  }
}
