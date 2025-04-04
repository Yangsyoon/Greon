import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/presentation/widgets/loading_shimmer.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';
import '../../data/models/product/product_model.dart'; // ProductModel import

class RectangularProductItem extends StatelessWidget {
  final ProductModel? product; // ProductModel로 변경
  final Function? onClick;
  final bool isFromWishlist;

  const RectangularProductItem({
    Key? key,
    this.product, // ProductModel로 변경
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
    // ProductModel에서 데이터 가져오기
    List<String> imageUrls = product!.images;
    String imageUrl = imageUrls.isNotEmpty
        ? (isFromWishlist ? imageUrls.last : imageUrls.first)
        : '';
    String name = product!.name;
    List priceTags = product!.priceTags;
    double price = priceTags.isNotEmpty ? priceTags.first['price'] ?? 0.0 : 0.0;
    String id = product!.id;

    // 디버깅용 URL 출력
    debugPrint("이미지 URL: $imageUrl");
    debugPrint("상품 이름: $name");
    debugPrint("가격: \$ $price");

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.productDetails,
          arguments: {
            'id': id,
            'name': name,
            'images': imageUrls,
            'priceTags': priceTags,
          },
        );
      },
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
              priceTags.isNotEmpty
                  ? Text(
                r'$ ' + price.toString(),
                style: AppText.h3?.copyWith(
                  color: AppColors.CommonCyan,
                ),
              )
                  : const SizedBox.shrink(),
              // URL을 화면에 표시
              Text(
                '이미지 URL: $imageUrl', // URL 화면에 출력
                style: AppText.b2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget placeholderShimmer() {
    return Container(); // placeholder shimmer
  }
}
