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
      print("🔥 LoadPosts triggered: category=${event.category}, sort=${event.sort}");
      emit(PostLoading());
      try {
        // 👇 Firestore 직접 호출 대신 Repository의 함수를 호출하도록 변경
        final posts = await postRepository.fetchPosts(
          category: event.category,
          sort: event.sort,
        );
        emit(PostLoaded(posts));
      } catch (e) {
        emit(PostError());
      }
    });

    on<ToggleLikePost>((event, emit) async {
      // Firestore 직접 접근 대신 Repository 함수 호출
      final newLikesCount = await postRepository.toggleLike(event.post.id, event.userId);

      // 로컬 상태 업데이트 로직은 더 간단해짐
      if (state is PostLoaded) {
        final currentState = state as PostLoaded;
        final updatedPosts = currentState.posts.map((p) {
          if (p.id == event.post.id) {
            return p.copyWith(likesCount: newLikesCount);
          }
          return p;
        }).toList();
        emit(PostLoaded(updatedPosts));
      }
    });
  }
}
