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
import '../widgets/rectangular_product_item.dart'; // RectangularProductItem import

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
      appBar: CustomAppBar('WISHLIST', context, automaticallyImplyLeading: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("정말 삭제하시겠습니까?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("취소"),
                ),
                TextButton(
                  onPressed: () {
                    context.read<WishlistCubit>().clearWishlist();
                    Navigator.pop(context);
                  },
                  child: Text("삭제"),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.delete_forever_outlined),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoadedState) {
            if (state.wishlist.isEmpty) {
              return Container(
                margin: EdgeInsets.only(
                    top: AppDimensions.normalize(90),
                    bottom: AppDimensions.normalize(120),
                    left: AppDimensions.normalize(10),
                    right: AppDimensions.normalize(10)),
                padding: Space.all(1, 1.5),
                color: AppColors.LightGrey,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        "NO FAVORITES",
                        style:
                        AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                      ),
                      const Text(
                        "There Is No Saved Products.\n Please Add New Products!",
                        style: TextStyle(height: 2),
                      )
                    ],
                  ),
                ),
              );
            } else {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where(FieldPath.documentId,
                    whereIn: state.wishlist.map((e) => e.id).toList())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('에러 발생: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.CommonCyan,
                        ));
                  }

                  final products = snapshot.data!.docs.map((doc) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;
                      data["id"] = doc.id;
                      return ProductModel.fromJson(data);
                    } catch (e) {
                      print('ProductModel 변환 오류: $e');
                      return null;
                    }
                  }).whereType<ProductModel>().toList();


                  return GridView.builder(
                    padding: Space.all(1),
                    itemCount: products.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7, // 값 조정
                      crossAxisSpacing: 6,
                    ),
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return RectangularProductItem(
                        product: products[index],
                        isFromWishlist: true,
                      );
                    },
                  );
                },
              );
            }
          } else {
            return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.CommonCyan,
                ));
          }
        },
      ),
    );
  }
}