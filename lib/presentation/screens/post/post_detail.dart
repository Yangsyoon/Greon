import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:greon/data/models/model/PostModel.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_post.dart';

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

  final Map<String, String> nicknameCache = {};
  final Map<String, TextEditingController> replyControllers = {};
  final Map<String, bool> showReplyFields = {};

  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post; // 초기 포스트 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 배경 투명 (앱 배경색이 보임)
        statusBarIconBrightness: Brightness.dark, // 안드로이드용 (아이콘/글씨 검정)
        statusBarBrightness: Brightness.light, // iOS용 (아이콘/글씨 검정)
      ),
    );
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(_post.id);

    await postRef.collection('comments').add({
      'uid': user.uid,
      'content': content,
      'targetUid': _post.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({'commentsCount': FieldValue.increment(1)});
    _commentController.clear();
  }

  Future<void> _addReply(String commentId, String content) async {
    if (content.trim().isEmpty) return;
    final user = _auth.currentUser;

    final commentDoc = await _firestore
        .collection('posts')
        .doc(_post.id)
        .collection('comments')
        .doc(commentId)
        .get();

    final commentAuthorUid = commentDoc['uid'];

    await _firestore
        .collection('posts')
        .doc(_post.id)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'content': content,
      'uid': user!.uid,
      'targetUid': commentAuthorUid, // 댓글 작성자에게 알림
      'createdAt': Timestamp.now(),
    });
  }

  Future<String> getNickname(String uid) async {
    if (nicknameCache.containsKey(uid)) return nicknameCache[uid]!;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final nickname = doc.data()?['nickname'] ?? '알 수 없음';
      nicknameCache[uid] = nickname;
      return nickname;
    } catch (e) {
      return '알 수 없음';
    }
  }

  Future<void> togglePostLike() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(_post.id);
    final likeDoc = await postRef.collection('likes').doc(user.uid).get();

    if (likeDoc.exists) {
      // 이미 좋아요 했으면 취소
      await postRef.collection('likes').doc(user.uid).delete();
      await postRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      // 좋아요 추가
      await postRef.collection('likes').doc(user.uid).set({'uid': user.uid});
      await postRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  Future<void> reportTarget(String targetId, String targetType, String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("신고 확인"),
        content: const Text("정말 신고하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("신고"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'targetId': targetId,
      'targetType': targetType, // "post" or "comment"
      'targetUid': targetUid,   // 신고 대상 작성자 uid
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("신고가 접수되었습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("게시판"),
          actions: [
            if (currentUser != null && currentUser.uid == _post.uid) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPostScreen(post: _post),
                    ),
                  );

                  if (updated != null && updated is PostModel) {
                    setState(() {
                      _post = updated;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("삭제 확인"),
                      content: const Text("정말 이 게시글을 삭제하시겠습니까?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("취소"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("삭제"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _firestore.collection('posts').doc(_post.id).delete();
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.network(
                  _post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            Text(_post.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FutureBuilder<String>(
                      future: getNickname(_post.uid),
                      builder: (context, snapshot) {
                        final nickname = snapshot.data ?? '로딩 중...';
                        return Text("작성자: $nickname",
                            style: const TextStyle(color: Colors.grey));
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(_post.createdAt),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                // 좋아요 버튼 & 카운트
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final user = _auth.currentUser;
                        if (user == null) return;

                        final postRef = _firestore.collection('posts').doc(_post.id);
                        final likeDoc = await postRef.collection('likes').doc(user.uid).get();

                        setState(() {
                          if (likeDoc.exists) {
                            // 좋아요 취소
                            _post.likesCount = (_post.likesCount ?? 1) - 1;
                          } else {
                            // 좋아요 추가
                            _post.likesCount = (_post.likesCount ?? 0) + 1;
                          }
                        });

                        // Firestore 업데이트
                        if (likeDoc.exists) {
                          await postRef.collection('likes').doc(user.uid).delete();
                          await postRef.update({'likesCount': FieldValue.increment(-1)});
                        } else {
                          await postRef.collection('likes').doc(user.uid).set({'uid': user.uid});
                          await postRef.update({'likesCount': FieldValue.increment(1)});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.thumb_up,
                          color: (_post.likesCount != null &&
                              _post.likesCount! > 0)
                              ? Colors.red
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${_post.likesCount ?? 0}'),

                    const SizedBox(width: 16),
                    // 신고 버튼
                    GestureDetector(
                      onTap: () => reportTarget(_post.id, "post", _post.uid),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.report, color: Colors.grey, size: 20),
                      ),
                    ),
                  ],
                )

              ],
            ),
            const Divider(height: 32),
            Text(_post.content, style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text("댓글",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(_post.id)
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

                return Column(
                  children: comments.map((comment) {
                    final commentId = comment.id;
                    final authorUid = comment['uid'] ?? '익명';
                    final content = comment['content'] ?? '';
                    final createdAt =
                        (comment['createdAt'] as Timestamp?)?.toDate();
                    final isMyComment = currentUser?.uid == authorUid;

                    replyControllers[commentId] ??= TextEditingController();
                    showReplyFields[commentId] ??= false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<String>(
                                future: getNickname(authorUid),
                                builder: (context, snapshot) {
                                  final nickname = snapshot.data ?? '로딩 중...';
                                  return Text(nickname,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold));
                                },
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.reply, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        showReplyFields[commentId] =
                                            !(showReplyFields[commentId] ??
                                                false);
                                      });
                                    },
                                  ),
                                  if (isMyComment) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () async {
                                        final newContent =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                            final editController =
                                                TextEditingController(
                                                    text: content);
                                            return AlertDialog(
                                              title: const Text('댓글 수정'),
                                              content: TextField(
                                                controller: editController,
                                                maxLines: null,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            "댓글 내용을 수정하세요"),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, null),
                                                  child: const Text("취소"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context,
                                                          editController.text
                                                              .trim()),
                                                  child: const Text("저장"),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (newContent != null &&
                                            newContent.isNotEmpty &&
                                            newContent != content) {
                                          await _firestore
                                              .collection('posts')
                                              .doc(_post.id)
                                              .collection('comments')
                                              .doc(commentId)
                                              .update({'content': newContent});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  title: const Text("댓글 삭제"),
                                                  content: const Text(
                                                      "이 댓글을 삭제하시겠습니까?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text("취소"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text("삭제"),
                                                    ),
                                                  ],
                                                ));

                                        if (confirm == true) {
                                          await _firestore
                                              .collection('posts')
                                              .doc(_post.id)
                                              .collection('comments')
                                              .doc(commentId)
                                              .delete();
                                          await _firestore
                                              .collection('posts')
                                              .doc(_post.id)
                                              .update({
                                            'commentsCount':
                                                FieldValue.increment(-1)
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.report, size: 18, color: Colors.grey),
                                    onPressed: () => reportTarget(commentId, "comment", authorUid),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          const SizedBox(height: 4),
                          Text(content),
                          // 대댓글 표시
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('posts')
                                .doc(_post.id)
                                .collection('comments')
                                .doc(commentId)
                                .collection('replies')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, replySnapshot) {
                              if (!replySnapshot.hasData ||
                                  replySnapshot.data!.docs.isEmpty) {
                                return const SizedBox();
                              }
                              final replies = replySnapshot.data!.docs;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, top: 4),
                                child: Column(
                                  children: replies.map((reply) {
                                    final replyAuthor = reply['uid'] ?? '';
                                    final replyContent = reply['content'] ?? '';
                                    final replyCreatedAt =
                                        (reply['createdAt'] as Timestamp?)
                                            ?.toDate();
                                    final isMyReply =
                                        currentUser?.uid == replyAuthor;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: FutureBuilder<String>(
                                        future: getNickname(replyAuthor),
                                        builder: (context, snapshot) {
                                          final nickname =
                                              snapshot.data ?? '로딩 중...';
                                          return Text(
                                            '$nickname: $replyContent',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          );
                                        },
                                      ),
                                      subtitle: replyCreatedAt != null
                                          ? Text(
                                              DateFormat('yyyy-MM-dd HH:mm')
                                                  .format(replyCreatedAt),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            )
                                          : null,
                                      trailing: isMyReply
                                          ? IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 18),
                                              onPressed: () async {
                                                await _firestore
                                                    .collection('posts')
                                                    .doc(_post.id)
                                                    .collection('comments')
                                                    .doc(commentId)
                                                    .collection('replies')
                                                    .doc(reply.id)
                                                    .delete();
                                              },
                                            )
                                          : null,
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          // 대댓글 작성 입력창
                          if (showReplyFields[commentId] == true)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 16.0, top: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: replyControllers[commentId],
                                      decoration: const InputDecoration(
                                        hintText: "대댓글 작성...",
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () async {
                                      await _addReply(commentId,
                                          replyControllers[commentId]!.text);
                                      replyControllers[commentId]!.clear();
                                      setState(() {
                                        showReplyFields[commentId] = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            // 새 댓글 작성 입력창
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "댓글 작성...",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
