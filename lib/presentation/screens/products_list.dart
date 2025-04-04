import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/products_bloc/product_bloc.dart';
import '../../configs/app_dimensions.dart';
import '../../configs/app_typography.dart';
import '../../configs/space.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';
import '../../core/error/failures.dart';
import '../../core/router/app_router.dart';
import '../../data/models/product/filter_params_model.dart';
import '../../data/models/product/price_tag_model.dart';
import '../../data/models/product/product_model.dart';
import '../../domain/entities/category/category.dart';
import '../widgets/black_dot.dart';
import '../widgets/noconnection_column.dart';


class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});
  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}
class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController scrollController = ScrollController();
  SortOrder? selectedSortOrder;
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
    scrollController.addListener(_scrollListener);
    super.initState();
  }

  Future<SortOrder?> showSortingOptions(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xfff6f6f6),
      constraints: BoxConstraints(minHeight: AppDimensions.normalize(150)),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                  top: AppDimensions.normalize(8),
                  left: AppDimensions.normalize(5),
                  bottom: AppDimensions.normalize(5)),
              child: Text(
                "SORT BY",
                style: AppText.h3b,
              ),
            ),
            ListTile(
              title: Text('Newest', style: AppText.h3),
              trailing: Radio(
                value: SortOrder.newest,
                fillColor: MaterialStateProperty.all(AppColors.CommonCyan),
                groupValue: selectedSortOrder,
                onChanged: (SortOrder? value) {
                  setState(() {
                    selectedSortOrder = value;
                  });
                  Navigator.pop(context, SortOrder.newest);
                },
              ),
            ),
            ListTile(
              title: Text('Price High to Low', style: AppText.h3),
              trailing: Radio(
                value: SortOrder.highToLow,
                fillColor: MaterialStateProperty.all(AppColors.CommonCyan),
                groupValue: selectedSortOrder,
                onChanged: (SortOrder? value) {
                  setState(() {
                    selectedSortOrder = value;
                  });
                  Navigator.pop(context, SortOrder.highToLow);
                },
              ),
            ),
            ListTile(
              title: Text('Price Low to High', style: AppText.h3),
              trailing: Radio(
                value: SortOrder.lowToHigh,
                fillColor: MaterialStateProperty.all(AppColors.CommonCyan),
                groupValue: selectedSortOrder,
                onChanged: (SortOrder? value) {
                  setState(() {
                    selectedSortOrder = value;
                  });
                  Navigator.pop(context, SortOrder.lowToHigh);
                },
              ),
            ),
            ListTile(
              title: Text('Alphabetic (A-Z)', style: AppText.h3),
              trailing: Radio(
                value: SortOrder.aToZ,
                fillColor: MaterialStateProperty.all(AppColors.CommonCyan),
                groupValue: selectedSortOrder,
                onChanged: (SortOrder? value) {
                  setState(() {
                    selectedSortOrder = value;
                  });
                  Navigator.pop(context, SortOrder.aToZ);
                },
              ),
            ),
            ListTile(
              title: Text('Alphabetic (Z-A)', style: AppText.h3),
              trailing: Radio(
                value: SortOrder.zToA,
                fillColor: MaterialStateProperty.all(AppColors.CommonCyan),
                groupValue: selectedSortOrder,
                onChanged: (SortOrder? value) {
                  setState(() {
                    selectedSortOrder = value;
                  });
                  Navigator.pop(context, SortOrder.zToA);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(top: AppDimensions.normalize(24)),
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoaded && state.products.isEmpty) {
              return Center(
                child: Text(
                  "Products not found!",
                  style: AppText.h3b,
                ),
              );
            }
            if (state is ProductError && state.products.isEmpty) {
              if (state.failure is NetworkFailure) {
                return Center(
                  child: Text(
                    "Network failure\nTry again!",
                    style: AppText.h3b,
                  ),
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (state.failure is ServerFailure ||
                      state.failure is CacheFailure)
                    const NoConnectionColumn(
                      isFromCategories: false,
                    )
                ],
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ProductBloc>()
                    .add(const GetProducts(FilterProductParams()));
              },
              child: Column(
                children: [
                  Padding(
                    padding: Space.h1!,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.search);
                            },
                            child: const Icon(Icons.search)),
                        BlocBuilder<FilterCubit, FilterProductParams>(
                          builder: (context, filterState) {
                            return filterState.categories.length == 0
                                ? Text(
                              "전체상품".toUpperCase(),
                              style: AppText.b1b
                                  ?.copyWith(color: AppColors.GreyText),
                            )
                                : Text(
                              filterState.categories.first.name
                                  .toUpperCase(),
                              style: AppText.b1b
                                  ?.copyWith(color: AppColors.GreyText),
                            );
                          },
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
                        )
                      ],
                    ),
                  ),
                  Space.y1!,
                  Container(
                    color: AppColors.LightGrey,
                    height: AppDimensions.normalize(25),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final sortOrder = await showSortingOptions(context);
                              if (sortOrder != null) {
                                setState(() {});
                                context
                                    .read<ProductBloc>()
                                    .add(SortProducts(sortOrder: sortOrder));
                              }
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(AppAssets.SortIcon),
                                selectedSortOrder == null
                                    ? const SizedBox.shrink()
                                    : BlackDot(),
                                Space.x!,
                                Text("정렬",
                                    style: AppText.b1
                                        ?.copyWith(color: AppColors.GreyText))
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: Space.vf(.5),
                            color: Colors.grey.shade400,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRouter.filter);
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(AppAssets.FilterIcon),
                                context.read<FilterCubit>().getFiltersCount() != 0
                                    ? BlackDot()
                                    : const SizedBox.shrink(),
                                Space.x!,
                                Text("필터",
                                    style: AppText.b1
                                        ?.copyWith(color: AppColors.GreyText))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Space.y!,
                  Expanded(
                    child: FutureBuilder<List<ProductModel>>(
                      future: FirebaseFirestore.instance.collection('products').get().then((snapshot) async {
                        try {
                          return await Future.wait(
                            snapshot.docs.map((doc) => ProductModel.fromDocumentAsync(doc)), // ✅ fromDocumentAsync 사용
                          );
                        } catch (e) {
                          debugPrint("Error fetching products: $e");
                          return [];
                        }
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          debugPrint("오류 발생: ${snapshot.error}");
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('에러 발생!'),
                                Text('오류 정보: ${snapshot.error}'),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('상품이 없습니다.'));
                        }

                        final List<ProductModel> products = snapshot.data!;

                        return GridView.builder(
                          padding: EdgeInsets.all(1), // Space.all(1) 대신 사용 (Space가 정의되지 않았을 수도 있음)
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
                            return RectangularProductItem(
                              product: products[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class RectangularProductItem extends StatelessWidget {
  final ProductModel product;

  const RectangularProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("선택한 상품: ${product.toJson()}");
        Navigator.of(context).pushNamed(
          AppRouter.productDetails,
          arguments: product.toEntity(),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: product.id,
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                height: AppDimensions.normalize(70),
                imageUrl: product.images.first, // 첫 번째 이미지 사용
                placeholder: (context, url) => placeholderShimmer(),
                errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
              )
                  : SvgPicture.asset(
                AppAssets.greonIcon,
                height: AppDimensions.normalize(70),
              ),
            ),
          ),
          Space.y!,
          Text(
            product.name,
            style: AppText.b2b,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Space.y!,
          Text(
            product.description,
            style: AppText.b2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget placeholderShimmer() {
    return Container(); // placeholder shimmer
  }
}