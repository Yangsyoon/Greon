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
import '../../core/router/app_router.dart';
import '../widgets/rectangular_product_item.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();

}

class _WishListScreenState extends State<WishListScreen> {
  Set<ProductModel> selectedItems = {};
  bool allSelected = false;

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
                        style: AppText.h3b?.copyWith(color: Colors.white),
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

            return Column(
              children: [
              SizedBox(
              height: 48,
                // ✅ 전체선택 / 선택삭제 UI
                child :Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.6, // 체크박스 크기 0.6배 축소
                        child: Checkbox(
                          value: allSelected,
                          onChanged: (val) {
                            setState(() {
                              allSelected = val!;
                              selectedItems = val ? wishlist.toSet() : {};
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '전체 선택',
                        style: TextStyle(fontSize: 8.4), // 글자 크기 0.6배 (기본 14로 가정)
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: selectedItems.isEmpty
                            ? null
                            : () {
                         // context.read<WishlistCubit>().removeFromWishlistBatch(selectedItems.toList());
                          setState(() {
                            selectedItems.clear();
                            allSelected = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 0), // 최소 크기 제한 해제
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.white,  // 텍스트 색상 흰색으로 지정
                          backgroundColor: Colors.red,    // 필요하면 버튼 배경색도 지정 가능 (예: 빨간색)
                        ),

                        child: const Text(
                          '선택 삭제',
                          style: TextStyle(fontSize: 8.4), // 버튼 텍스트 크기도 0.6배
                        ),
                      ),
                    ],
                  ),
                ),
              ),


                // ✅ GridView
                Expanded(
                  child: GridView.builder(
                    padding: Space.all(1),
                    itemCount: wishlist.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 6,
                    ),
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final productModel = wishlist[index];
                      final isSelected = selectedItems.contains(productModel);

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.productDetails, arguments: productModel.toEntity());
                        },
                        onLongPress: () {
                          setState(() {
                            if (isSelected) {
                              selectedItems.remove(productModel);
                            } else {
                              selectedItems.add(productModel);
                            }
                            allSelected = selectedItems.length == wishlist.length;
                          });
                        },
                        child: Stack(
                          children: [
                            RectangularProductItem(
                              product: productModel,
                              isFromWishlist: true,
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle, color: Colors.green),
                              ),
                          ],
                        ),
                      );

                    },
                  ),
                ),
              ],
            );
          }
          // ❗ 다른 모든 경우의 기본 처리
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}
