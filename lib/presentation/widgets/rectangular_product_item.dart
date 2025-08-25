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
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: isFromWishlist ? Space.all(.5, .5) : Space.all(1, 1),
              child: SizedBox(
                height: 130, // 이미지 높이 키움
                child: Hero(
                  tag: id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,  // 사진 꽉 차게
                      placeholder: (context, url) => Center(child: placeholderShimmer()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    )
                        : SvgPicture.asset(
                      AppAssets.greonIcon,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 5),

            Padding(
              padding: isFromWishlist ? Space.all(.5, .5) : Space.all(1, 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppText.h3b?.copyWith(fontSize: (AppText.h3b?.fontSize ?? 18) * 0.8),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),
                  Text(
                    category.isNotEmpty ? category[0].name : '',
                    style: TextStyle(
                      fontSize: (AppText.h3?.fontSize ?? 14) * 0.8,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),
                  Text(
                    price.toString() + r'원',
                    style: AppText.h3?.copyWith(
                      color: Colors.black,
                      fontSize: (AppText.h3?.fontSize ?? 14) * 0.8,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }

  Widget placeholderShimmer() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}