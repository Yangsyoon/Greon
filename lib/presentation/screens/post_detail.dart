import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:greon/data/models/model/PostModel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(widget.post.id);

    await postRef.collection('comments').add({
      'uid': user.uid,             // author → uid 로 저장
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({'commentsCount': FieldValue.increment(1)});

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 상세보기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.post.title,
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("작성자: ${widget.post.uid}",
                    style: const TextStyle(color: Colors.grey)), // author → uid
                const SizedBox(width: 12),
                Text(DateFormat('yyyy-MM-dd HH:mm').format(widget.post.createdAt),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            Text(widget.post.content, style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text("댓글",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(widget.post.id)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("아직 댓글이 없습니다."));
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final authorUid = comment['uid'] ?? '익명'; // author → uid
                      final content = comment['content'] ?? '';
                      final createdAt =
                      (comment['createdAt'] as Timestamp?)?.toDate();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(authorUid,
                                style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(content),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: "댓글을 입력하세요...",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null, // 여러 줄 입력 가능
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addComment,
                    child: const Text("등록", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
