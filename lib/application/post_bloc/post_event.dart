import '../../data/models/model/PostModel.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {
  final String? category; // nullable로 선언하여 전체 불러오기 가능
  LoadPosts({this.category});
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