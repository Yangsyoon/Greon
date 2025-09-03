import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/unlogged_profile_container.dart';

import '../../application/user_bloc/user_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _adPageController = PageController(viewportFraction: 0.9);
  int _currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAdAutoSlide();
  }

  void _startAdAutoSlide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_adPageController.hasClients) {
        final nextPage = _currentAdIndex + 1;
        _adPageController.animateToPage(
          nextPage % 1000, // 무한 루프
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      _startAdAutoSlide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: Space.h1!,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "마이페이지",
                  style: AppText.h2b?.copyWith(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      if (state is UserLogged) {
                        final user = firebase.FirebaseAuth.instance.currentUser;
                        final image = user?.photoURL;

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final nickname = data?['nickname'] ?? '닉네임 없음';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // 프로필 사진 + 닉네임
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage:
                                      image != null ? NetworkImage(image) : null,
                                      child: image == null
                                          ? const Icon(Icons.person, size: 28)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      nickname,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // 4개 버튼
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _profileActionButton(
                                      context,
                                      icon: Icons.shopping_bag,
                                      label: '주문내역',
                                      onTap: () => Navigator.pushNamed(context, '/orders'),
                                    ),
                                    _profileActionButton(
                                      context,
                                      icon: Icons.notifications,
                                      label: '알림내역',
                                      onTap: () =>
                                          Navigator.pushNamed(context, '/notifications'),
                                    ),
                                    _profileActionButton(
                                      context,
                                      icon: Icons.help_outline,
                                      label: '문의',
                                      onTap: () =>
                                          Navigator.pushNamed(context, '/inquiries'),
                                    ),
                                    _profileActionButton(
                                      context,
                                      icon: Icons.card_giftcard,
                                      label: '쿠폰',
                                      onTap: () =>
                                          Navigator.pushNamed(context, '/coupons'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Firestore 기반 광고 슬라이드
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('ads')
                                      .snapshots(),
                                  builder: (context, adSnapshot) {
                                    if (!adSnapshot.hasData ||
                                        adSnapshot.data!.docs.isEmpty) {
                                      return const SizedBox(height: 180);
                                    }

                                    final adDocs = adSnapshot.data!.docs;

                                    return Column(
                                      children: [
                                        SizedBox(
                                          height: 180,
                                          child: PageView.builder(
                                            controller: _adPageController,
                                            itemCount: adDocs.length,
                                            onPageChanged: (index) {
                                              setState(() => _currentAdIndex = index);
                                            },
                                            itemBuilder: (context, index) {
                                              final adData =
                                              adDocs[index].data() as Map<String, dynamic>;
                                              final imageUrl = adData['url'] as String?;
                                              final link = adData['link'] as String?;
                                              return GestureDetector(
                                                onTap: () async {
                                                  if (link != null) {
                                                    final uri = Uri.parse(link);
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    } else {
                                                      print("링크를 열 수 없습니다: $link");
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
                                                    image: imageUrl != null
                                                        ? DecorationImage(
                                                      image: NetworkImage(imageUrl),
                                                      fit: BoxFit.cover,
                                                    )
                                                        : null,
                                                    color: Colors.grey[300],
                                                  ),
                                                  child: imageUrl == null
                                                      ? const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // 페이지 인디케이터
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            adDocs.length,
                                                (index) => Container(
                                              margin: const EdgeInsets.symmetric(
                                                  horizontal: 4),
                                              width: _currentAdIndex == index ? 12 : 8,
                                              height: _currentAdIndex == index ? 12 : 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _currentAdIndex == index
                                                    ? Colors.black
                                                    : Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        );
                      } else {
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            unloggedProfileContainer(context),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
