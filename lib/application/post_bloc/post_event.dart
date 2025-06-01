import '../../data/models/model/PostModel.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {}

class AddPost extends PostEvent {
  final PostModel post;
  AddPost(this.post);
}