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
import 'package:greon/presentation/widgets/quantity_row.dart';
import 'package:screenshot/screenshot.dart';

import '../../application/cart_bloc/cart_bloc.dart';
import '../../application/wishlist_cubit/wishlist_cubit.dart';
import '../../data/models/product/product_model.dart';
import '../../domain/entities/cart/cart_item.dart';
import '../../domain/entities/product/price_tag.dart';
import '../widgets/dots_indicator.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/proceedtocart_modalsheet.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ProductEntity product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  PageController _pageController = PageController();
  ScrollController _listController = ScrollController();
  int _selectedPageIndex = 0;
  late PriceTag _selectedPriceTag;

  @override
  void initState() {
    super.initState();
    _selectedPriceTag = widget.product.priceTags.first;
    _pageController.addListener(() {
      setState(() {
        _selectedPageIndex = _pageController.page?.round() ?? 0;
        _listController.animateTo(
          _selectedPageIndex * 116.0,
          // Adjust this value based on your item width and margin
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    App.init(context);
    bool isProductInWishlist =
    context.read<WishlistCubit>().isInWishlist(widget.product.id);
    return Screenshot(
      controller: context.read<ShareCubit>().screenshotController,
      child: Scaffold(
        appBar: CustomAppBar("PRODUCT DETAILS", context,
            doesHasCartIcom: true, automaticallyImplyLeading: true),
        body: Padding(
          padding: Space.all(.9, .7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h2b,
                ),
                Space.yf(.6),
                Text(
                  "${widget.product.priceTags.first.price} \$",
                  style: AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                ),
                Space.yf(.6),
                Row(
                  children: [
                    Text(
                      "Category Name : ",
                      style: AppText.h3,
                    ),
                    Text(
                      widget.product.categories.first.name.toUpperCase(),
                      style: AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                    ),
                  ],
                ),
                Space.yf(1.1),
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
                Container(
                  height: AppDimensions.normalize(50),
                  color: AppColors.LightGrey,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _listController,
                    itemCount: widget.product.images.length,
                    physics: const ClampingScrollPhysics(),
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
                            color: AppColors.LightGrey,
                            border: Border.all(
                              color: _selectedPageIndex == index
                                  ? AppColors
                                  .CommonCyan // Change this to your desired color
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
                Container(
                  color: AppColors.LightGrey,
                  margin: Space.v,
                  padding: Space.all(.5, .5),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          isProductInWishlist
                              ? GestureDetector(
                              onTap: () {
                                /*setState(() {
                                      context
                                          .read<WishlistCubit>()
                                          .removeFromWishlist(
                                              ProductModel.fromEntity(
                                                  widget.product));
                                    });*/
                              },
                              child: const Icon(Icons.favorite))
                              : GestureDetector(
                              onTap: () {
                                setState(() {
                                  context
                                      .read<WishlistCubit>()
                                      .addToWishlist(
                                      ProductModel.fromEntity(
                                          widget.product));
                                });
                              },
                              child: const Icon(Icons.favorite_border)),
                          Space.xf(.3),
                          Text(
                            "Add to wishlist",
                            style: AppText.h3,
                          )
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
                          context.read<ShareCubit>().shareScreenshot();
                        },
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.Share,
                              height: AppDimensions.normalize(10),
                            ),
                            Space.xf(.7),
                            Text(
                              "Share",
                              style: AppText.h3,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Space.yf(1.2),
                Text(
                  "Description",
                  style: AppText.h3b,
                ),
                Space.yf(.5),
                Text(
                  widget.product.description,
                  style:
                  AppText.b2?.copyWith(height: AppDimensions.normalize(.6)),
                ),
                Space.yf(1.2),
                Text(
                  "Prices",
                  style: AppText.h3b,
                ),
                Space.yf(.5),
                Wrap(
                  children: widget.product.priceTags
                      .map((priceTag) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPriceTag = priceTag;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: _selectedPriceTag.id == priceTag.id
                              ? 2.7
                              : 1.0,
                          color: AppColors.CommonCyan,
                        ),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(5.0)),
                      ),
                      padding: const EdgeInsets.all(8),
                      margin:
                      const EdgeInsets.only(right: 7, bottom: 5),
                      child: Column(
                        children: [
                          Text(priceTag.name),
                          Text("${priceTag.price} \$"),
                        ],
                      ),
                    ),
                  ))
                      .toList(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: QuantityRow(17, 2)),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(
                      AddProduct(
                        cartItem: CartItem(
                            product: widget.product,
                            priceTag: _selectedPriceTag),
                      ),
                    );
                    context.read<NotificationsCubit>().showAndSaveNotification(
                        "Cart Update",
                        "Congratulations, You have successfully added ${widget.product.name} to your cart.");
                    showPoceedtoCartBottomSheet(context);
                  },
                  child: Text(
                    "Add to cart",
                    style: AppText.h3b?.copyWith(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}