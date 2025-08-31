import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greon/presentation/screens/post/post.dart';
import 'package:greon/presentation/screens/product/products_list.dart';
import 'package:greon/presentation/screens/register_plant.dart';
import 'package:greon/presentation/screens/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/plants/plant_entity.dart';
import 'plant_detail_screen.dart';
import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/wishlist_cubit/wishlist_cubit.dart';
import '../../application/post_bloc/post_bloc.dart';
import '../../application/post_bloc/post_event.dart';
import '../../application/post_bloc/post_state.dart';
import '../../application/products_bloc/product_bloc.dart';
import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';
import '../../core/router/app_router.dart';
import '../../configs/app.dart';
import '../../configs/configs.dart';
import '../widgets/dots_indicator.dart';
import '../widgets/error_container.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/square_product_item.dart';
import '../widgets/top_row.dart';
import 'my_plants_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPage = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPage);
    context.read<FilterCubit>().reset();
    context.read<WishlistCubit>().loadWishlist();
    context.read<PostBloc>().add(LoadPosts());
    context.read<ProductBloc>().add(GetProducts(context.read<FilterCubit>().state));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 배경 투명 (앱 배경색이 보임)
        statusBarIconBrightness: Brightness.dark, // 안드로이드용 (아이콘/글씨 검정)
        statusBarBrightness: Brightness.light, // iOS용 (아이콘/글씨 검정)
      ),
    );
  }

  Future<String?> getPlantImageUrl(String userId, String plantId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('user_plant/$userId/$plantId.jpg');
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    App.init(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        child:SingleChildScrollView(
          padding: Space.h1!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 로고 & 환경설정 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(AppAssets.greonAppBar, height: 40),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                      },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Center(
                child: Text(
                  "지금 내 식물은?",
                  style: AppText.h2b?.copyWith(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // ✅ 내 식물 그리드뷰 (모두 표시)
              if (userId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('plant')
                      .where('user_id', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plants = snapshot.data!.docs
                        .map((doc) => PlantEntity.fromFirestore(doc))
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1), // 테두리
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                      child: plants.isEmpty
                          ? Container(
                        height: 150,
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_florist, size: 60, color: Colors.green),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 한 줄에 2개
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8, // 비율 조정
                        ),
                        itemCount: plants.length,
                        itemBuilder: (context, index) {
                          final plant = plants[index];
                          return FutureBuilder<String?>(
                            future: getPlantImageUrl(userId, plant.id),
                            builder: (context, imgSnapshot) {
                              final imgUrl = imgSnapshot.data;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlantDetailScreen(plant: plant),
                                    ),
                                  );
                                  },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: imgUrl != null
                                          ? Image.network(
                                        imgUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.eco, size: 40, color: Colors.green),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      plant.name,
                                      style: AppText.b1b,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                              },
                          );
                          },
                      ),
                    );
                    },
                ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterPlant()),
                        );
                        },
                      child: const Text("식물 등록하기"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<NavigationCubit>().updateTab(NavigationTab.values[2]); // 내 식물 탭으로 이동
                      },
                      child: const Text("내 식물 관리하기"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

                  // 슬라이드 뷰
              SizedBox(
                height: AppDimensions.normalize(110),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (pos) {
                        setState(() {
                          currentPage = pos;
                        });
                        },
                      itemCount: AppAssets.bannerImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(AppAssets.bannerUrls[index]);
                            print(uri.toString());
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.platformDefault,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('URL을 열 수 없습니다.')),
                              );
                            }
                            },
                          child: Image.asset(
                            AppAssets.bannerImages[index],
                            fit: BoxFit.cover,
                          ),
                        );
                        },
                    ),
                    Positioned(
                      bottom: AppDimensions.normalize(2),
                      left: 0,
                      right: 0,
                      child: Dotsindicator(
                        dotsIndex: _pageController.hasClients ? _pageController.page?.round() : 1,
                        dotsCount: AppAssets.bannerImages.length,
                        activeColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ 게시판 카테고리 버튼
              _buildBoardCategoryButtons(context),

              // 판매 모종
              _buildProductsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 새로 만든 카테고리 버튼 UI
  Widget _buildBoardCategoryButtons(BuildContext context) {
    final categories = ["정보공유", "QnA", "자유"];
    final base = 'assets/images/';
    final imageUrls = [base+'info.png', base+'qna.png', base+'free.png'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "게시판",
          style: AppText.h2b?.copyWith(color: Colors.black),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(categories.length, (index) {
            final cat = categories[index];
            return Expanded(
              child: GestureDetector(
                  onTap: () {
                    context.read<NavigationCubit>().updateTabWithCategory(
                      NavigationTab.boardTab,
                      cat,
                    );
                  },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(imageUrls[index]),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 6),
                    Text(cat, style: AppText.b1b),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("상점", style: AppText.h2b?.copyWith(color: Colors.black)),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    final List<Map<String, String>> categories = [
      {'name': '전체', 'image': 'assets/images/all.png'},
      {'name': '꽃', 'image': 'assets/images/flower.png'},
      {'name': '관엽식물', 'image': 'assets/images/leaf.png'},
      {'name': '다육식물', 'image': 'assets/images/succulent.png'},
      {'name': '허브', 'image': 'assets/images/herb.png'},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              context.read<NavigationCubit>().updateTabWithCategory(
                NavigationTab.shoppingTab,
                category['name']!,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(category['image']!),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name']!,
                    style: AppText.b1b,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
