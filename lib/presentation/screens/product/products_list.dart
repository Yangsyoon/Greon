import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../../application/bottom_navbar_cubit/navigation_state.dart';
import '../../../application/filter_cubit/filter_cubit.dart';
import '../../../application/products_bloc/product_bloc.dart';
import '../../../configs/app_dimensions.dart';
import '../../../configs/app_typography.dart';
import '../../../configs/space.dart';
import '../../../core/constant/assets.dart';
import '../../../core/constant/colors.dart';
import '../../../core/enums/enums.dart';
import '../../../core/error/failures.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/product/filter_params_model.dart';
import '../../../data/models/product/product_model.dart';
import '../../../domain/entities/product/product.dart';
import '../../widgets/noconnection_column.dart';
import '../../widgets/rectangular_product_item.dart';
import '../settings_page.dart';

class ProductsListScreen extends StatefulWidget {
  final String initialCategory;

  @override
  const ProductsListScreen({
    super.key,
    this.initialCategory = '전체', // 기본값
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final List<Map<String, String>> availableCategories = [
    {'name': '전체', 'image': 'assets/images/all.png'},
    {'name': '꽃', 'image': 'assets/images/flower.png'},
    {'name': '관엽식물', 'image': 'assets/images/leaf.png'},
    {'name': '다육식물', 'image': 'assets/images/succulent.png'},
    {'name': '허브', 'image': 'assets/images/herb.png'},
  ];
  String selectedCategory = '전체';
  String selectedSort = '가격 순'; // 초기값 설정

  void _scrollListener() {
    double maxScroll = scrollController.position.maxScrollExtent;
    double currentScroll = scrollController.position.pixels;
    double scrollPercentage = 0.7;

    if (currentScroll > (maxScroll * scrollPercentage)) {
      if (context.read<ProductBloc>().state is ProductLoaded) {
        context.read<ProductBloc>().add(const GetMoreProducts());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    final navigationState = context.read<NavigationCubit>().state;
    if (navigationState.category != null) {
      selectedCategory = navigationState.category!;
    }
    context.read<FilterCubit>().applyCategory(navigationState.category ?? '전체');
  }

  @override
  void dispose() {
    scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<FilterCubit>().applySearch('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationCubit, NavigationState>(
      listener: (context, state) {
        if (state.tab == NavigationTab.shoppingTab && state.category != null) {
          setState(() {
            selectedCategory = state.category!;
          });
          // FilterCubit에도 변경된 카테고리 적용
          context.read<FilterCubit>().applyCategory(state.category!);
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_isSearching) {
            _exitSearchMode();
            return false;
          }
          return true;
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: Space.h1!,
                        child: Column(
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
                            const SizedBox(height: 12),
                            // 2. 검색창/검색아이콘 + 선택된 카테고리 텍스트
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSearching = true;
                                      _searchController.clear();
                                    });
                                    context.read<FilterCubit>().applySearch('');
                                  },
                                  child: const Icon(Icons.search),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _isSearching
                                      ? SizedBox(
                                          width: double.infinity,
                                          child: TextField(
                                            controller: _searchController,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              hintText: "상품 검색",
                                              border: InputBorder.none,
                                            ),
                                            onChanged: (value) {
                                              context
                                                  .read<FilterCubit>()
                                                  .applySearch(value.trim());
                                            },
                                            onSubmitted: (_) {
                                              FocusScope.of(context).unfocus();
                                            },
                                          ))
                                      : BlocBuilder<FilterCubit,
                                          FilterProductParams>(
                                          builder: (context, filterState) {
                                            return Text(
                                              (filterState.categories.isEmpty
                                                      ? " "
                                                      : filterState.categories
                                                          .first.name)
                                                  .toUpperCase(),
                                              style: AppText.b1b?.copyWith(
                                                  color: AppColors.GreyText),
                                              textAlign: TextAlign.center,
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // 왼쪽 4/5 영역: 가로로 넘기는 이미지 스크롤 뷰
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 200, // 필요한 이미지 높이로 조절
                                child: PageView(
                                  scrollDirection: Axis.horizontal,
                                  children: List.generate(
                                    5, // 이미지 개수
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'assets/images/shop_picture.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), // 영역 간 간격
                            // 오른쪽 1/5 영역: 버튼 3개 세로 배치
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed(AppRouter.cart);
                                      },
                                      child: Image.asset(
                                        'assets/images/cart.png',
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed(AppRouter.wishlist);
                                      },
                                      child: Image.asset(
                                        'assets/images/jjim.png',
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // 클릭 시 동작
                                      },
                                      child: Image.asset(
                                        'assets/images/coupon.png',
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100, // 이미지+텍스트 전체 높이
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableCategories.map((category) {
                              final isSelected =
                                  selectedCategory == category['name'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category['name']!;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 동그란 이미지
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.grey,
                                            width: 2,
                                          ),
                                          image: DecorationImage(
                                            image:
                                                AssetImage(category['image']!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // 카테고리 이름
                                      Text(
                                        category['name']!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.green
                                              : Colors.black,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                ['가격 순', '리뷰 많은 순', '추천 순', '인기순'].map((title) {
                              final isSelected =
                                  selectedSort == title; // 선택 상태 관리 변수
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedSort = title;
                                    });
                                    // 정렬 로직 호출 가능
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    foregroundColor: Colors.black,
                                    side: BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: Text(title),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16), // 왼쪽 16px 띄우기
                          child: Text(
                            '판매 모종 >',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Space.y1!,
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ProductBloc>()
                          .add(const GetProducts(FilterProductParams()));
                    },
                    child: _isSearching
                        ? BlocBuilder<FilterCubit, FilterProductParams>(
                            builder: (context, filterState) {
                              final products = filterState.products;
                              if (products.isEmpty) {
                                return const Center(
                                    child: Text('검색 결과가 없습니다.'));
                              }
                              return _buildGrid(products);
                            },
                          )
                        : BlocBuilder<ProductBloc, ProductState>(
                            builder: (context, state) {
                              if (state is ProductLoaded) {
                                final products = state.products;
                                return _buildGridOrEmpty(products, '상품이 없습니다.');
                              } else if (state is ProductError) {
                                if (state.failure is NetworkFailure) {
                                  return const Center(
                                      child: Text("네트워크 오류\n다시 시도해주세요"));
                                } else {
                                  return const NoConnectionColumn(
                                      isFromCategories: false);
                                }
                              } else {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ProductEntity> _filterByCategory(List<ProductEntity> products) {
    if (selectedCategory == '전체') return products;
    return products.where((p) {
      if (p.categories.isEmpty) return false;
      final name = p.categories[0].name;
      return name == selectedCategory;
    }).toList();
  }

  Widget _buildGridOrEmpty(List<ProductEntity> products, String emptyMessage) {
    final filtered = _filterByCategory(products);
    if (filtered.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return _buildGrid(filtered);
  }

  Widget _buildGrid(List<ProductEntity> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      itemCount: products.length,
      controller: scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 6,
      ),
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        final productModel = ProductModel.fromEntity(products[index]);
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRouter.productDetails,
              arguments: products[index],
            );
          },
          child: RectangularProductItem(
            product: productModel,
          ),
        );
      },
    );
  }
}
