import '../../data/models/model/PostModel.dart';

abstract class PostState {}

class PostInitial extends PostState {}
class PostLoading extends PostState {}
class PostLoaded extends PostState {
  final List<PostModel> posts;
  PostLoaded(this.posts);
}
class PostError extends PostState {}

class PostAddSuccess extends PostState {}

class PostAddFailure extends PostState {
  final String errorMessage;
  PostAddFailure(this.errorMessage);
}