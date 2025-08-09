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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    context.read<FilterCubit>().reset();
    context.read<WishlistCubit>().loadWishlist();
    context.read<PostBloc>().add(LoadPosts());
    context.read<ProductBloc>().add(GetProducts(context.read<FilterCubit>().state));
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
        bottom: true, // ✅ 하단 네비게이션 버튼 영역 침범 방지
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),

              Text(
                "지금 내 식물은?",
                style: AppText.h2b?.copyWith(color: Colors.black),
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

                    if (plants.isEmpty) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: const Center(
                          child: Icon(Icons.local_florist, size: 60, color: Colors.green),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // ✅ 한 줄에 2개
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
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
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: imgUrl != null
                                          ? Image.network(
                                        imgUrl,
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        height: 100,
                                        color: Colors.grey[200],
                                        alignment: Alignment.center, // 추가: 아이콘 중앙 정렬
                                        child: const Icon(
                                          Icons.eco,
                                          size: 50, // 높이 100인데 아이콘 50이 적당
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Text(
                                        plant.name,
                                        style: AppText.b1b,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyPlantsScreen()),
                        );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("게시판", style: AppText.h2b?.copyWith(color: Colors.black)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: categories.map((cat) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BulletinBoardScreen(initialCategory: cat),
                      ),
                    );
                  },
                  child: Text(cat),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("판매모종", style: AppText.h2b?.copyWith(color: Colors.black)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsListScreen()),
                );
              },
              child: const Text("모두보기"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return SizedBox(
          height: AppDimensions.normalize(100),
          child: (state is ProductError)
              ? Center(child: errorContainer(context, false))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state is ProductLoading ? 3 : state.products.length,
            itemBuilder: (context, index) {
              if (state is ProductLoading) return const SquareProductItem();
              return SquareProductItem(product: state.products[index]);
            },
          ),
        );
      },
    );
  }
}
