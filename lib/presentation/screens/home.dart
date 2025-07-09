import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greon/application/products_bloc/product_bloc.dart';
import 'package:greon/application/wishlist_cubit/wishlist_cubit.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/error_container.dart';
import 'package:greon/presentation/widgets/loading_shimmer.dart';
import 'package:greon/presentation/widgets/square_product_item.dart';
import 'package:greon/presentation/widgets/top_row.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/post_bloc/post_bloc.dart';
import '../../application/post_bloc/post_event.dart';
import '../../application/post_bloc/post_state.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';
import '../../core/router/app_router.dart';
import '../widgets/dots_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPage = 1;
  PageController _pageController = PageController();

  @override
  void initState() {
    _pageController = PageController(initialPage: currentPage);
    context.read<FilterCubit>().reset();
    context.read<WishlistCubit>().loadWishlist();
    context.read<PostBloc>().add(LoadPosts());
    context
        .read<ProductBloc>()
        .add(GetProducts(context.read<FilterCubit>().state));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    App.init(context);
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(top: AppDimensions.normalize(22)),
        child: Padding(
          padding: Space.h1!,
          child: Column(
            children: [
              TopRow(isFromHome: true, context: context),
              Space.yf(.2),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return SvgPicture.asset(
                                    AppAssets.greonIcon,
                                    fit: BoxFit.cover,
                                  );
                                }),
                            Positioned(
                              bottom: AppDimensions.normalize(2),
                              left: 0,
                              right: 0,
                              child: Dotsindicator(
                                dotsIndex: _pageController.hasClients
                                    ? _pageController.page?.round()
                                    : 1,
                                dotsCount: 3,
                                activeColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: AppDimensions.normalize(15),
                            bottom: AppDimensions.normalize(7)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "게시판",
                                  style: AppText.h2b?.copyWith(color: AppColors.CommonCyan),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.read<NavigationCubit>().updateTab(NavigationTab.boardTab);
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        "모두 보기",
                                        style: AppText.b2b?.copyWith(color: AppColors.CommonCyan),
                                      ),
                                      const Icon(Icons.double_arrow, size: 15),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<PostBloc, PostState>(
                              builder: (context, state) {
                                if (state is PostLoading) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (state is PostLoaded) {
                                  final posts = state.posts.take(5).toList(); // 최대 5개까지 보여줌

                                  return SizedBox(
                                    height: AppDimensions.normalize(60), // 높이 조절
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: posts.length,
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final post = posts[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              AppRouter.postDetail,
                                              arguments: post,
                                            );
                                          },
                                          child: Container(
                                            width: AppDimensions.normalize(80), // 카드 너비
                                            margin: const EdgeInsets.only(right: 12), // 카드 간 간격
                                            child: Card(
                                              elevation: 2,
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      post.title,
                                                      style: AppText.b1b,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      post.content.length > 50
                                                          ? post.content.substring(0, 50) + "..."
                                                          : post.content,
                                                      style: AppText.b2,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                } else {
                                  return const Text("게시글을 불러올 수 없습니다.");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: AppDimensions.normalize(3.5),
                            bottom: AppDimensions.normalize(7)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "판매 모종",
                              style: AppText.h2b
                                  ?.copyWith(color: AppColors.CommonCyan),
                            ),
                            GestureDetector(
                              onTap: () {
                                context
                                    .read<NavigationCubit>()
                                    .updateTab(NavigationTab.productsTap);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    "모두 보기",
                                    style: AppText.b2b
                                        ?.copyWith(color: AppColors.CommonCyan),
                                  ),
                                  Icon(
                                    Icons.double_arrow,
                                    size: 15,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          return SizedBox(
                            height: AppDimensions.normalize(100),
                            child: (state is ProductError)
                                ? Center(child: errorContainer(context, false))
                                : (state is ProductEmpty)
                                ? Text(
                              "No Featured Products Available",
                              style: AppText.b1b,
                              overflow: TextOverflow.ellipsis,
                            )
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              physics: const ClampingScrollPhysics(),
                              itemBuilder: (context, index) => (state
                              is ProductLoading)
                                  ? const SquareProductItem()
                                  : state.products.isNotEmpty
                                  ? SquareProductItem(
                                product:
                                state.products[index],
                              )
                                  : LoadingShimmer(
                                  isSquare: true),
                            ),
                          );
                        },
                      ),
                      Space.y2!
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

