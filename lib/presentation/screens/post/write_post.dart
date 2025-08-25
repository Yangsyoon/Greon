import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String selectedCategory = '정보공유';

  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final filePath =
          'post_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(image);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
          );
          return;
        }
      }

      final newPost = PostModel(
        id: '',
        title: _titleController.text,
        content: _contentController.text,
        uid: user.uid,
        createdAt: DateTime.now(),
        commentsCount: 0,
        likesCount: 0,
        imageUrl: imageUrl,
        category: selectedCategory,
      );

      context.read<PostBloc>().add(AddPost(newPost));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocListener<PostBloc, PostState>(
              listener: (context, state) {
                if (state is PostAddSuccess) {
                  Navigator.pop(context, true); // 모달 닫기
                } else if (state is PostAddFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('게시글 등록에 실패했습니다: ${state.errorMessage}')),
                  );
                }
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "글 작성",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: '제목'),
                            validator: (value) =>
                            value == null || value.isEmpty ? '제목을 입력하세요' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            items: ['정보공유', 'QnA', '자유'].map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: '게시판',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: '내용'),
                      maxLines: 8,
                      validator: (value) =>
                      value == null || value.isEmpty ? '내용을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey.shade200,
                        ),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : const Center(child: Text('이미지 선택 (클릭)')),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text("등록하기"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

