import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/app_typography.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/presentation/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/product/product_model.dart';
import '../../application/wishlist_cubit/wishlist_cubit.dart';
import 'package:greon/application/wishlist_cubit/wishlist_cubit.dart';
import '../widgets/rectangular_product_item.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  @override
  void initState() {
    context.read<WishlistCubit>().loadWishlist();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar('위시리스트', context, automaticallyImplyLeading: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("정말 삭제하시겠습니까?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소"),
                ),
                TextButton(
                  onPressed: () {
                    context.read<WishlistCubit>().clearWishlist();
                    Navigator.pop(context);
                  },
                  child: const Text("삭제"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.delete_forever_outlined),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoadedState) {
            final wishlist = state.wishlist;

            if (wishlist.isEmpty) {
              return Container(
                margin: EdgeInsets.only(
                  top: AppDimensions.normalize(90),
                  bottom: AppDimensions.normalize(120),
                  left: AppDimensions.normalize(10),
                  right: AppDimensions.normalize(10),
                ),
                padding: Space.all(1, 1.5),
                color: AppColors.LightGrey,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "상품이 없습니다",
                        style: AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "등록된 상품이 없습니다.\n 새로운 상품을 추가해보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 2),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: Space.all(1),
              itemCount: wishlist.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 6,
              ),
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                final product = wishlist[index];
                return RectangularProductItem(
                  product: product,
                  isFromWishlist: true,
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.CommonCyan,
              ),
            );
          }
        },
      ),
    );
  }
}
