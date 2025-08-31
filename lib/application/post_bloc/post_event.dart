import '../../data/models/model/PostModel.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {
  final String? category;
  final String sort;
  LoadPosts({
    this.category,
    this.sort = '최신순', // 기본값은 최신순
  });
}

class AddPost extends PostEvent {
  final PostModel post;
  AddPost(this.post);
}

class ToggleLikePost extends PostEvent {
  final PostModel post;
  final String userId;

  ToggleLikePost({required this.post, required this.userId});
}