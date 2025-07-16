import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../application/post_bloc/post_bloc.dart';
import '../../../application/post_bloc/post_event.dart';
import '../../../application/post_bloc/post_state.dart';
import '../../widgets/noconnection_column.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final Map<String, String> nicknameCache = {};
  @override
  void initState() {
    super.initState();
    context.read<PostBloc>().add(LoadPosts());
  }

  Future<String> getNickname(String uid) async {
    if (nicknameCache.containsKey(uid)) return nicknameCache[uid]!;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final nickname = snapshot.data()?['nickname'] ?? '알 수 없음';
      nicknameCache[uid] = nickname;
      return nickname;
    } catch (e) {
      return '알 수 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌿 식물 게시판", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/write-post');
          if (result == true) {
            context.read<PostBloc>().add(LoadPosts());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<PostBloc, PostState>(
            builder: (context, state) {
              if (state is PostLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is PostLoaded) {
                if (state.posts.isEmpty) {
                  return const Center(child: Text("게시글이 없습니다."));
                }
                return ListView.builder(
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            FutureBuilder<String>(
                              future: getNickname(post.uid),
                              builder: (context, snapshot) {
                                final nickname = snapshot.data ?? '로딩 중...';
                                return Text(nickname, style: const TextStyle(fontSize: 12, color: Colors.grey));
                              },
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.comment, size: 16, color: Colors.grey),
                            Text('${post.commentsCount}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/post-detail',
                            arguments: post,
                          );
                          if (result == true) {
                            context.read<PostBloc>().add(LoadPosts());
                          }
                        },
                      ),
                    );
                  },
                );
              } else if (state is PostError) {
                return const NoConnectionColumn(isFromCategories: false);
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}
