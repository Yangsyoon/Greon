import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/application/post_bloc/post_event.dart';
import 'package:greon/application/post_bloc/post_state.dart';
import '../../data/repositories/post_repository.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository postRepository;

  PostBloc(this.postRepository) : super(PostInitial()) {
    on<LoadPosts>((event, emit) async {
      emit(PostLoading());
      try {
        final posts = await postRepository.fetchPosts();
        emit(PostLoaded(posts));
      } catch (_) {
        emit(PostError());
      }
    });
    on<AddPost>((event, emit) async {
      try {
        await postRepository.addPost(event.post);
        emit(PostAddSuccess());  // 성공 상태 emit
      } catch (e) {
        emit(PostAddFailure(e.toString()));  // 실패 상태 emit
      }
    });
  }
}
