import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/product/product_model.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistInitialState());

  Future<void> loadWishlist() async {
    final box = GetStorage();
    final List<dynamic>? wishlistData = box.read('wishlist');

    if (wishlistData == null) {
      emit(const WishlistLoadedState([]));
      return;
    }

    List<ProductModel> wishlist = wishlistData
        .whereType<Map<String, dynamic>>()
        .map((jsonMap) => ProductModel.fromJson(jsonMap))
        .toList();

    emit(WishlistLoadedState(wishlist));
  }

  Future<void> addToWishlist(ProductModel product) async {
    final box = GetStorage();
    final List<dynamic>? wishlistData = box.read('wishlist');

    final List<Map<String, dynamic>> updatedWishlist =
    List<Map<String, dynamic>>.from(wishlistData ?? []);

    updatedWishlist.add(product.toJson());

    box.write('wishlist', updatedWishlist);

    if (state is WishlistLoadedState) {
      emit(WishlistLoadedState(
          (state as WishlistLoadedState).wishlist + [product]));
    } else {
      emit(WishlistLoadedState([product]));
    }
  }

  Future<void> clearWishlist() async {
    final box = GetStorage();
    await box.remove('wishlist');
    emit(const WishlistLoadedState([]));
  }

  bool isInWishlist(String productId) {
    final box = GetStorage();
    List<dynamic>? wishlistData = box.read<List<dynamic>>('wishlist');

    if (wishlistData == null) {
      return false;
    }

    List<String> wishlistIds = wishlistData
        .whereType<Map<String, dynamic>>()
        .map((map) => map['id'].toString())
        .toList();

    return wishlistIds.contains(productId);
  }
}