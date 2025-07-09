import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/presentation/widgets/loading_shimmer.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/product/product_model.dart';
import '../../domain/entities/category/category.dart';

class RectangularProductItem extends StatelessWidget {
  final ProductModel? product;
  final Function? onClick;
  final bool isFromWishlist;

  const RectangularProductItem({
    Key? key,
    this.product,
    this.onClick,
    this.isFromWishlist = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return product == null
        ? LoadingShimmer(isSquare: true)
        : buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    List<String> imageUrls = product!.images;
    String imageUrl = imageUrls.isNotEmpty
        ? (isFromWishlist ? imageUrls.last : imageUrls.first)
        : '';
    String name = product!.name;
    int price = product!.price;
    String id = product!.id;
    List<Category> category = product!.categories;

    return GestureDetector(
      onTap: onClick != null ? () => onClick!() : null,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.only(bottom: AppDimensions.normalize(10.8)),
        child: Padding(
          padding: isFromWishlist ? Space.all(.5, .5) : Space.all(1, 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: id,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  height: AppDimensions.normalize(70),
                  imageUrl: imageUrl,
                  placeholder: (context, url) => placeholderShimmer(),
                  errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
                )
                    : SvgPicture.asset(
                  AppAssets.greonIcon,
                  height: AppDimensions.normalize(70),
                ),
              ),
              Space.y1!,
              Text(
                name,
                style: AppText.h3b,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Space.y!,
              Text(
                category[0].name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Space.y!,
              Text(
                price.toString() + r'원',
                style: AppText.h3?.copyWith(
                  color: AppColors.CommonCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget placeholderShimmer() {
    return Container(); // 필요 시 shimmer 위젯 교체
  }
}
