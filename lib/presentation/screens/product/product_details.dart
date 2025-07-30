import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greon/application/notifications_cubit/notifications_cubit.dart';
import 'package:greon/application/share_cubit/share_cubit.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/domain/entities/product/product.dart';
import 'package:greon/presentation/widgets/custom_appbar.dart';
import 'package:greon/presentation/widgets/photo_view_dialog.dart';
import 'package:screenshot/screenshot.dart';
import '../../../application/cart_bloc/cart_bloc.dart';
import '../../../application/wishlist_cubit/wishlist_cubit.dart';
import '../../../data/models/product/product_model.dart';
import '../../../domain/entities/cart/cart_item.dart';
import '../../widgets/dots_indicator.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/proceedtocart_modalsheet.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductEntity product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  final ScrollController _listController = ScrollController();

  int _selectedPageIndex = 0;
  int _quantity = 1;
  bool? _isInWishlist;

  @override
  void initState() {
    super.initState();
    _loadWishlistStatus();

    _pageController.addListener(() {
      setState(() {
        _selectedPageIndex = _pageController.page?.round() ?? 0;
        _listController.animateTo(
          _selectedPageIndex * 116.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  Future<void> _loadWishlistStatus() async {
    final isInWishlist =
    await context.read<WishlistCubit>().isInWishlist(widget.product.id);
    setState(() {
      _isInWishlist = isInWishlist;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.init(context);

    return Scaffold(
      appBar: CustomAppBar("제품 상세 정보", context,
          doesHasCartIcom: true, automaticallyImplyLeading: true),
      body: Padding(
        padding: Space.all(.9, .7),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h2b),
              Space.yf(.6),
              Text("${widget.product.price} 원",
                  style: AppText.h3b?.copyWith(color: AppColors.CommonCyan)),
              Space.yf(.6),
              Row(
                children: [
                  Text("카테고리 : ", style: AppText.h3),
                  Text(widget.product.categories.first.name.toUpperCase(),
                      style: AppText.h3b?.copyWith(color: AppColors.CommonCyan)),
                ],
              ),
              Space.yf(1.1),
              // 이미지 뷰
              Stack(
                children: [
                  Container(
                    height: AppDimensions.normalize(130),
                    color: AppColors.LightGrey,
                    padding: Space.all(0, 1),
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.product.images.length,
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedPageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                showPhotoViewDialog(
                                    widget.product.images[index], context);
                              },
                              child: Hero(
                                tag: widget.product.id,
                                child: CachedNetworkImage(
                                  fit: BoxFit.contain,
                                  imageUrl: widget.product.images[index],
                                  placeholder: (context, url) =>
                                      placeholderShimmer(),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: AppDimensions.normalize(.1),
                          left: 0,
                          right: 0,
                          child: Dotsindicator(
                            dotsIndex: _pageController.hasClients
                                ? _pageController.page?.round()
                                : 0,
                            dotsCount: widget.product.images.length,
                            activeColor: AppColors.CommonCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 썸네일 리스트
              Container(
                height: AppDimensions.normalize(50),
                color: AppColors.LightGrey,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _listController,
                  itemCount: widget.product.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: Space.all(.2, .2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedPageIndex == index
                                ? AppColors.CommonCyan
                                : Colors.transparent,
                            width: 5.0,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.images[index],
                          placeholder: (context, url) => placeholderShimmer(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 위시리스트 & 공유
              Container(
                color: AppColors.LightGrey,
                margin: Space.v,
                padding: Space.all(.5, .5),
                child: Row(
                  children: [
                    Row(
                      children: [
                        if (_isInWishlist == null)
                          const CircularProgressIndicator()
                        else
                          GestureDetector(
                            onTap: () async {
                              final cubit = context.read<WishlistCubit>();
                              final model =
                              ProductModel.fromEntity(widget.product);
                              if (_isInWishlist!) {
                                await cubit.removeFromWishlist(model.id);
                              } else {
                                await cubit.addToWishlist(model);
                              }
                              await _loadWishlistStatus();
                            },
                            child: Icon(
                              _isInWishlist!
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                          ),
                        Space.xf(.3),
                        Text("위시리스트에 추가", style: AppText.h3)
                      ],
                    ),
                    Space.xf(.8),
                    Container(
                      height: AppDimensions.normalize(10),
                      width: 1,
                      color: Colors.grey,
                    ),
                    Space.xf(2.5),
                    GestureDetector(
                      onTap: () async {
                        context.read<ShareCubit>().shareStoreLink();
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(AppAssets.Share,
                              height: AppDimensions.normalize(10)),
                          Space.xf(.7),
                          Text("공유", style: AppText.h3),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Space.yf(1.2),
              Text("상세 설명", style: AppText.h3b),
              Space.yf(.5),
              Text(
                widget.product.description,
                style: AppText.b2?.copyWith(height: AppDimensions.normalize(.6)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.LightGrey,
        height: AppDimensions.normalize(33),
        padding: Space.all(.7, .9),
        margin: EdgeInsets.only(
            top: AppDimensions.normalize(1),
            bottom: AppDimensions.normalize(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<CartBloc>().add(
                  AddProduct(
                    cartItem: CartItem(
                      product: widget.product,
                      price: widget.product.price,
                      quantity: 1,
                    ),
                  ),
                );
                context.read<NotificationsCubit>().showAndSaveNotification(
                    "카트 업데이트",
                    "${widget.product.name}가 카트에 추가되었습니다.");
                showPoceedtoCartBottomSheet(context);
              },
              child: Text(
                "카트에 추가",
                style: AppText.h3b?.copyWith(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
