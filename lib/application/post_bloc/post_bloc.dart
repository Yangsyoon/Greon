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

        emit(PostLoaded(posts));
      } catch (e) {
        emit(PostError());
      }
    });
    on<AddPost>((event, emit) async {
      try {
        await postRepository.addPost(event.post);
        emit(PostAddSuccess());
      } catch (e) {
        emit(PostAddFailure(e.toString()));
      }
    });
  }
}
