import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final List<String> availableCategories = ['전체', '꽃', '관엽식물', '다육식물', '허브'];
  String selectedCategory = '전체';

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
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          _exitSearchMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          minimum: EdgeInsets.only(top: AppDimensions.normalize(24)),
          child: Column(
            children: [
              Padding(
                padding: Space.h1!,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Expanded(
                      child: _isSearching
                          ? TextField(
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
                          FocusScope.of(context).unfocus(); // 키보드 닫기
                        },
                      )
                          : BlocBuilder<FilterCubit, FilterProductParams>(
                        builder: (context, filterState) {
                          return Text(
                            (filterState.categories.isEmpty
                                ? "전체상품"
                                : filterState.categories.first.name)
                                .toUpperCase(),
                            style: AppText.b1b?.copyWith(
                                color: AppColors.GreyText),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.cart);
                      },
                      child: SvgPicture.asset(
                        AppAssets.Cart,
                        color: AppColors.CommonCyan,
                        height: AppDimensions.normalize(10),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: availableCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    setState(() {
                      selectedCategory = newValue;
                    });
                  },
                ),
              ),
              Space.y1!,
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
                          return const Center(child: Text("네트워크 오류\n다시 시도해주세요"));
                        } else {
                          return const NoConnectionColumn(isFromCategories: false);
                        }
                      } else {
                        return const Center(child: CircularProgressIndicator());
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
        childAspectRatio: 0.55,
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
