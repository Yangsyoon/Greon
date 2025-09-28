import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../../application/filter_cubit/filter_cubit.dart';
import '../../../application/post_bloc/post_bloc.dart';
import '../../../application/post_bloc/post_event.dart';
import '../../../application/post_bloc/post_state.dart';
import '../../../configs/app_typography.dart';
import '../../../configs/space.dart';
import '../../../core/constant/assets.dart';
import '../../../core/enums/enums.dart';
import '../../../data/models/model/PostModel.dart';
import '../../../data/models/product/filter_params_model.dart';
import '../../widgets/noconnection_column.dart';
import '../settings_page.dart';

class BulletinBoardScreen extends StatefulWidget {
  final String? initialCategory;

  const BulletinBoardScreen({super.key, this.initialCategory});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final Map<String, String> nicknameCache = {};
  String selectedCategory = '전체';
  String selectedSort = '최신순';
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
          LoadPosts(
              category: selectedCategory == '전체' ? null : selectedCategory),
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
        if (navState.tab == NavigationTab.boardTab &&
            navState.category != null) {
          setState(() {
            selectedCategory = navState.category!;
          });
          context.read<PostBloc>().add(
                LoadPosts(category: navState.category),
              );
        }
      },
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: true,
          child: Padding(
            padding: Space.h1!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(AppAssets.greonAppBar, height: 40),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "게시판",
                    style: AppText.h2b?.copyWith(color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 끝 정렬
                  children: [
                    TextButton(
                      onPressed: () async {
                        final result =
                            await Navigator.pushNamed(context, '/write-post');
                        if (result == true) {
                          context.read<PostBloc>().add(
                                LoadPosts(
                                    category: selectedCategory == '전체'
                                        ? null
                                        : selectedCategory),
                              );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          "글쓰기",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedSort,
                      items: ['최신순', '추천순']
                          .map((sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(sort),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSort = value;
                          });
                          context.read<PostBloc>().add(
                                LoadPosts(
                                  category: selectedCategory == '전체'
                                      ? null
                                      : selectedCategory,
                                  sort: value,
                                ),
                              );
                        }
                      },
                    ),
                    Expanded(child:
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final isSelected = selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: Colors.grey[400],
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      selectedCategory = cat;
                                    });
                                    context.read<PostBloc>().add(
                                      LoadPosts(
                                        category: cat == '전체' ? null : cat,
                                        sort: selectedSort, // 현재 선택된 정렬 유지
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  post.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      post.content ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 6),
                                    FutureBuilder<String>(
                                       future: getNickname(post.uid),
                                       builder: (context, snapshot) {
                                         final nickname =
                                             snapshot.data ?? '로딩 중...';
                                         final timeAgo =
                                             _formatTimeAgo(post.createdAt);

                                         return Row(
                                           children: [
                                             BlocBuilder<PostBloc, PostState>(
                                               builder: (context, state) {
                                                 // 현재 상태에서 해당 게시글 가져오기
                                                 PostModel currentPost = post;
                                                 if (state is PostLoaded) {
                                                   final found =
                                                       state.posts.firstWhere(
                                                     (p) => p.id == post.id,
                                                     orElse: () => post,
                                                   );
                                                   currentPost = found;
                                                 }
                                                 return Row(
                                                   children: [
                                                     if (currentPost.likesCount >
                                                         0) ...[
                                                       const Icon(Icons.thumb_up,
                                                           size: 20,
                                                           color: Colors.red),
                                                       const SizedBox(width: 2),
                                                       Text(
                                                         '${currentPost.likesCount}',
                                                        style: const TextStyle(
                                                           fontSize: 12,
                                                           color: Colors.grey,
                                                           fontWeight:
                                                               FontWeight.bold,
                                                        ),
                                                       ),
                                                       const SizedBox(width: 8),
                                                     ],
                                                     if (currentPost
                                                             .commentsCount >
                                                         0) ...[
                                                       const Icon(Icons.comment,
                                                           size: 20,
                                                           color: Colors
                                                               .lightBlueAccent),
                                                       const SizedBox(width: 2),
                                                       Text(
                                                         '${currentPost.commentsCount}',
                                                         style: const TextStyle(
                                                           fontSize: 12,
                                                           color: Colors.grey,
                                                           fontWeight:
                                                               FontWeight.bold,
                                                         ),
                                                       ),
                                                       const SizedBox(width: 20),
                                                     ],
                                                     Text(
                                                       "$timeAgo  |  $nickname",
                                                       style: const TextStyle(
                                                           fontSize: 12,
                                                           color: Colors.grey),
                                                     ),
                                                   ],
                                                 );
                                               },
                                             )
                                           ],
                                         );
                                       },
                                     ),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/post-detail',
                                    arguments: post,
                                  );
                                  if (result == true) {
                                    context.read<PostBloc>().add(
                                          LoadPosts(
                                              category: selectedCategory == '전체'
                                                  ? null
                                                  : selectedCategory),
                                        );
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

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) return "방금 전";
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    if (diff.inDays < 7) return "${diff.inDays}일 전";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}주 전";
    if (diff.inDays < 365) return "${(diff.inDays / 30).floor()}개월 전";
    return "${(diff.inDays / 365).floor()}년 전";
  }
}
