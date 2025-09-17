import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/unlogged_profile_container.dart';
import 'package:greon/data/models/product/product_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/user_bloc/user_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/room_style_classifier.dart';
import '../widgets/profile_action_button.dart';

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
  // AI 모델 서비스 인스턴스 생성
  final RoomStyleClassifier _classifier = RoomStyleClassifier();
  final ImagePicker _picker = ImagePicker();

  // 쿠폰 버튼 클릭 시 호출될 함수
  void _onCouponButtonPressed(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('사진 촬영이 취소되었습니다.')));
        return;
      }

      File imageFile = File(photo.path);
      // 서비스 클래스의 classifyImage 함수 호출
      String? result = await _classifier.classifyImage(imageFile);

      // 결과 다이얼로그 표시
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('방 스타일 분석 결과'),
            content: Text(result ?? '분석 실패'),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('카메라 또는 모델 실행 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
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
      body:
      Padding(
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
                                _buildProfileHeader(image, nickname),
                                const SizedBox(height: 24),
                                _buildProfileActionButtons(context),
                                const SizedBox(height: 24),
                                _buildAdsSection(),
                                const SizedBox(height: 24),
                                // 최근 본 상품
                                const RecentlyViewedList(),
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

  Widget _buildProfileHeader(String? image, String nickname) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: image != null ? NetworkImage(image) : null,
          child: image == null ? const Icon(Icons.person, size: 28) : null,
        ),
        const SizedBox(width: 12),
        Text(
          nickname,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileActionButtons(BuildContext context) {
    return Row(
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
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _profileActionButton(
          context,
          icon: Icons.help_outline,
          label: '문의',
          onTap: () => Navigator.pushNamed(context, '/inquiries'),
        ),
        _profileActionButton(
          context,
          icon: Icons.card_giftcard,
          label: '쿠폰',
          onTap: () => _onCouponButtonPressed(context),
        ),
      ],
    );
  }

  Widget _buildAdsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ads').snapshots(),
      builder: (context, adSnapshot) {
        if (!adSnapshot.hasData || adSnapshot.data!.docs.isEmpty) {
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
                onPageChanged: (index) => setState(() => _currentAdIndex = index),
                itemBuilder: (context, index) {
                  final adData = adDocs[index].data() as Map<String, dynamic>;
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
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                          ))
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                adDocs.length,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentAdIndex == index ? 12 : 8,
                  height: _currentAdIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentAdIndex == index ? Colors.black : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

/// 최근 본 상품 위젯
class RecentlyViewedList extends StatelessWidget {
  const RecentlyViewedList({super.key});

  Future<List<ProductModel>> _fetchRecentlyViewed() async {
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recently_viewed')
        .orderBy('viewedAt', descending: true)
        .limit(10)
        .get();

    final ids = snapshot.docs.map((doc) => doc.id).toList();

    final products = await Future.wait(ids.map((id) async {
      final doc = await FirebaseFirestore.instance.collection('products').doc(id).get();
      if (!doc.exists) return ProductModel.errorModel(id);
      return ProductModel.fromDocumentAsync(doc);
    }));

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: _fetchRecentlyViewed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text("최근 본 상품이 없습니다.")),
          );
        }

        final products = snapshot.data!;

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/product-details',
                    arguments: product.toEntity(),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                    image: product.images.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(product.images.first),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: product.images.isEmpty
                      ? const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  )
                      : Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      color: Colors.black54,
                      child: Text(
                        product.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
