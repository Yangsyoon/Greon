import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/product/product_model.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final FirebaseFirestore firestore;
  final String userId;

  WishlistCubit({required this.firestore, required this.userId}) : super(WishlistInitialState());

  Future<void> loadWishlist() async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      final wishlistRefs = userDoc.data()?['wishlist'] as List<dynamic>?;

      if (wishlistRefs == null || wishlistRefs.isEmpty) {
        emit(const WishlistLoadedState([]));
        return;
      }

      List<ProductModel> wishlist = [];

      for (final ref in wishlistRefs) {
        if (ref is DocumentReference) {
          final doc = await ref.get();
          if (doc.exists) {
            try {
              final product = await ProductModel.fromDocumentAsync(doc);
              wishlist.add(product);
            } catch (e) {
              print("❌ 변환 실패: ${doc.id} - $e");
            }
          }
        }
      }

      emit(WishlistLoadedState(wishlist));
    } catch (e) {
      print("❌ Wishlist 로딩 오류: $e");
      emit(const WishlistLoadedState([]));
    }
  }

  Future<void> addToWishlist(ProductModel product) async {
    final productRef = firestore.collection('products').doc(product.id);
    try {
      await firestore.collection('users').doc(userId).update({
        'wishlist': FieldValue.arrayUnion([productRef])
      });

      if (state is WishlistLoadedState) {
        emit(WishlistLoadedState((state as WishlistLoadedState).wishlist + [product]));
      } else {
        emit(WishlistLoadedState([product]));
      }
    } catch (e) {
      print("❌ 위시리스트 추가 오류: $e");
    }
  }

  Future<void> removeFromWishlist(ProductModel product) async {
    final productRef = firestore.collection('products').doc(product.id);
    try {
      await firestore.collection('users').doc(userId).update({
        'wishlist': FieldValue.arrayRemove([productRef])
      });

      if (state is WishlistLoadedState) {
        final updatedList = List<ProductModel>.from((state as WishlistLoadedState).wishlist)
          ..removeWhere((item) => item.id == product.id);
        emit(WishlistLoadedState(updatedList));
      }
    } catch (e) {
      print("❌ 위시리스트 제거 오류: $e");
    }
  }

  Future<void> clearWishlist() async {
    try {
      await firestore.collection('users').doc(userId).update({'wishlist': []});
      emit(const WishlistLoadedState([]));
    } catch (e) {
      print("❌ 위시리스트 초기화 오류: $e");
    }
  }

  bool isInWishlist(String productId) {
    if (state is WishlistLoadedState) {
      return (state as WishlistLoadedState)
          .wishlist
          .any((product) => product.id == productId);
    }
    return false;
  }
}
