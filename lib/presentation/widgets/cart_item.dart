import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/presentation/widgets/dashed_separator.dart';
import 'package:greon/presentation/widgets/loading_shimmer.dart';
import 'package:greon/presentation/widgets/quantity_row.dart';

import '../../application/cart_bloc/cart_bloc.dart';
import '../../core/router/app_router.dart';
import '../../domain/entities/cart/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem? cartItem;
  final Function? onFavoriteToggle;
  final Function? onClick;
  final Function()? onLongClick;
  final VoidCallback? onDelete;
  final bool isSelected;

  const CartItemCard({
    Key? key,
    this.cartItem,
    this.onFavoriteToggle,
    this.onClick,
    this.onLongClick,
    this.onDelete,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return cartItem == null
        ? LoadingShimmer(isSquare: false)
        : buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    final cart = cartItem!;
    return Column(
      children: [
        Space.yf(1),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRouter.productDetails,
              arguments: cart.product,
            );
          },
          onLongPress: onLongClick,
          child: SizedBox(
            height: AppDimensions.normalize(50),
            width: double.infinity,
            child: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: (cart.product.images.isNotEmpty)
                      ? cart.product.images.last
                      : 'https://via.placeholder.com/150', // 또는 앱에서 지정한 기본 이미지
                  width: AppDimensions.normalize(50),
                  height: double.infinity,
                  fit: BoxFit.fill,
                  placeholder: (context, url) =>
                      LoadingShimmer(isSquare: false),
                  errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
                ),

                Space.xf(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppDimensions.normalize(75),
                      child: Text(
                        cart.product.name,
                        maxLines: 2,
                        style: AppText.h3b,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Space.yf(.5),
                    Text(
                      "${cart.product.price} 원",
                      style: AppText.h3b?.copyWith(
                        color: AppColors.CommonCyan,
                      ),
                    ),
                    Space.yf(),
                    Row(
                      children: [
                        SizedBox(
                          height: AppDimensions.normalize(15),
                          width: AppDimensions.normalize(55),
                          child: QuantityRow(
                            quantity: cartItem?.quantity ?? 1,
                            padding: 8,
                            onIncrease: () {
                              if (cartItem != null) {
                                context.read<CartBloc>().add(IncreaseCartItemQuantity(cartItem!));
                              }
                            },
                            onDecrease: () {
                              if (cartItem != null) {
                                context.read<CartBloc>().add(DecreaseCartItemQuantity(cartItem!));
                              }
                            },
                          )
                        ),
                        Space.xf(),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_forever_outlined,
                            size: 40,
                            color: Colors.black54,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        Space.yf(1),
        const DashedSeparator()
      ],
    );
  }
}
