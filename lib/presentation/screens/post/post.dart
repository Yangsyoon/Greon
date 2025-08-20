import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../../application/filter_cubit/filter_cubit.dart';
import '../../../application/post_bloc/post_bloc.dart';
import '../../../application/post_bloc/post_event.dart';
import '../../../application/post_bloc/post_state.dart';
import '../../../core/enums/enums.dart';
import '../../../data/models/product/filter_params_model.dart';
import '../../widgets/noconnection_column.dart';

class BulletinBoardScreen extends StatefulWidget {
  final String? initialCategory;

  const BulletinBoardScreen({super.key, this.initialCategory});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final Map<String, String> nicknameCache = {};
  String selectedCategory = '전체';
  final List<String> categories = ['전체', '정보공유', 'QnA', '자유'];

  @override
  void initState() {
    super.initState();
    final navState = context.read<NavigationCubit>().state;
    if (navState.category != null) {
      selectedCategory = navState.category!;
    } else {
      final filterState = context.read<FilterCubit>().state;
      selectedCategory = filterState.categories.isNotEmpty
          ? filterState.categories.first.name
          : '전체';
    }
    context.read<PostBloc>().add(
      LoadPosts(category: selectedCategory == '전체' ? null : selectedCategory),
    );
  }

  Future<String> getNickname(String uid) async {
    if (nicknameCache.containsKey(uid)) return nicknameCache[uid]!;
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final nickname = snapshot.data()?['nickname'] ?? '알 수 없음';
      nicknameCache[uid] = nickname;
      return nickname;
    } catch (e) {
      return '알 수 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, navState) {
        if (navState.tab == NavigationTab.boardTab && navState.category != null) {
          setState(() {
            selectedCategory = navState.category!;
          });
          context.read<PostBloc>().add(
            LoadPosts(category: navState.category),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("🌿 그리온 게시판", style: TextStyle(color: Colors.green)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.green),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/write-post');
            if (result == true) {
              context.read<PostBloc>().add(LoadPosts(
                  category:
                  selectedCategory == '전체' ? null : selectedCategory));
            }
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    items: categories.map((cat) {
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
                        context.read<PostBloc>().add(
                          LoadPosts(category: value == '전체' ? null : value),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
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
                                title: Text(post.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    FutureBuilder<String>(
                                      future: getNickname(post.uid),
                                      builder: (context, snapshot) {
                                        final nickname =
                                            snapshot.data ?? '로딩 중...';
                                        return Text(nickname,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey));
                                      },
                                    ),
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(post.createdAt),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.comment,
                                        size: 16, color: Colors.grey),
                                    Text('${post.commentsCount}',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/post-detail',
                                    arguments: post,
                                  );
                                  if (result == true) {
                                    context.read<PostBloc>().add(LoadPosts(
                                        category: selectedCategory == '전체'
                                            ? null
                                            : selectedCategory));
                                  }
                                },
                              ),
                            );
                          },
                        );
                      } else if (state is PostError) {
                        return const NoConnectionColumn(
                            isFromCategories: false);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}