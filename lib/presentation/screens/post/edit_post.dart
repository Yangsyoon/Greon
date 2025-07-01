import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greon/data/models/model/PostModel.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _imageUrl = widget.post.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrl = null; // 새 이미지 선택 시 기존 URL 무효화
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final filePath =
          'post_images/${widget.post.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(image);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _updatePost() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? imageUrlToSave = _imageUrl;

        if (_selectedImage != null) {
          final uploadedUrl = await _uploadImage(_selectedImage!);
          if (uploadedUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
            );
            return;
          }
          imageUrlToSave = uploadedUrl;
        }

        final docRef = _firestore.collection('posts').doc(widget.post.id);

        await docRef.update({
          'title': _titleController.text,
          'content': _contentController.text,
          'imageUrl': imageUrlToSave,
        });

        final updatedDoc = await docRef.get();
        final updatedData = updatedDoc.data();

        if (updatedData != null) {
          final updatedPost = PostModel(
            id: updatedDoc.id,
            uid: updatedData['uid'],
            title: updatedData['title'],
            content: updatedData['content'],
            createdAt: (updatedData['createdAt'] as Timestamp).toDate(),
            commentsCount: updatedData['commentsCount'] ?? 0,
            imageUrl: updatedData['imageUrl'] as String?,
          );

          Navigator.pop(context, updatedPost);
        } else {
          Navigator.pop(context, null);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 수정")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
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
                      : (_imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : const Center(child: Text('이미지 선택 (클릭)'))),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updatePost,
                child: const Text("수정하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
