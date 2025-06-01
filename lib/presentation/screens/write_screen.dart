import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/application/post_bloc/post_bloc.dart';
import 'package:greon/application/post_bloc/post_event.dart';
import 'package:greon/application/post_bloc/post_state.dart';
import 'package:greon/data/models/model/PostModel.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      final newPost = PostModel(
        id: '',
        title: _titleController.text,
        content: _contentController.text,
        uid: user.uid,  // 여기 uid 넣기
        createdAt: DateTime.now(),
        commentsCount: 0,
      );

      // 이벤트로 게시글 추가 요청
      context.read<PostBloc>().add(AddPost(newPost));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("글 작성")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<PostBloc, PostState>(
          listener: (context, state) {
            if (state is PostAddSuccess) {
              // 성공하면 게시판 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/bulletin-board',
                    (route) => false,
              );
            } else if (state is PostAddFailure) {
              // 실패하면 에러 토스트 또는 다이얼로그 보여주기
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('게시글 등록에 실패했습니다: ${state.errorMessage}')),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                  validator: (value) =>
                  value == null || value.isEmpty ? '제목을 입력하세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: 8,
                  validator: (value) =>
                  value == null || value.isEmpty ? '내용을 입력하세요' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text("등록하기"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
