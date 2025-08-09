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
        const Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey, // 원하시는 색상으로 조절
        ),
        Space.yf(0.5),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onLongClick?.call(),
                  activeColor: Colors.black,
                ),
                SizedBox(width: 4),
                //  이미지 + 수량조절
                Column(
                  children: [
                    CachedNetworkImage(
                      imageUrl: (cart.product.images.isNotEmpty)
                          ? cart.product.images.last
                          : 'https://via.placeholder.com/150',
                      width: AppDimensions.normalize(30),
                      height: AppDimensions.normalize(30),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          LoadingShimmer(isSquare: false),
                      errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.error)),
                    ),
                    Space.yf(0.5),
                    SizedBox(
                      height: AppDimensions.normalize(15),
                      width: AppDimensions.normalize(55),
                      child: QuantityRow(
                        quantity: cartItem?.quantity ?? 1,
                        padding: 8,
                        onIncrease: () {
                          if (cartItem != null) {
                            context.read<CartBloc>().add(
                                IncreaseCartItemQuantity(cartItem!));
                          }
                        },
                        onDecrease: () {
                          if (cartItem != null) {
                            context.read<CartBloc>().add(
                                DecreaseCartItemQuantity(cartItem!));
                          }
                        },
                      ),
                    ),
                  ],
                ),

                Space.xf(),

                // ✅ 텍스트 + 삭제아이콘 + 가격
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제품명 + 삭제 아이콘
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제품 이름
                          Expanded(
                            child: Text(
                              cart.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.h3b,
                            ),
                          ),
                          // 삭제 아이콘
                          GestureDetector(
                            onTap: onDelete,
                            child: Image.asset(
                              'assets/images/delete_icon.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ],
                      ),
                      Space.yf(3.5),
                      Text(
                        "${cart.product.price} 원",
                        style: AppText.h3b?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
