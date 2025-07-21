import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/product/product_model.dart';

part 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit() : super(WishlistInitialState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> loadWishlist() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final wishlistSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      List<ProductModel> wishlist = [];

      for (var doc in wishlistSnapshot.docs) {
        final ref = doc.data()['ref'] as DocumentReference;
        final productSnap = await ref.get();
        if (productSnap.exists) {
          final product = await ProductModel.fromDocumentAsync(productSnap);
          wishlist.add(product);
        }
      }


      emit(WishlistLoadedState(wishlist));
    } catch (e) {
      log('❌ Failed to load wishlist: $e');
      emit(const WishlistLoadedState([]));
    }
  }

  Future<void> addToWishlist(ProductModel product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(product.id); // 문서 ID = productId

      await wishlistRef.set({
        'ref': _firestore.collection('products').doc(product.id), // 문서 참조 저장
      });

      if (state is WishlistLoadedState) {
        final current = (state as WishlistLoadedState).wishlist;
        emit(WishlistLoadedState([...current, product]));
      } else {
        emit(WishlistLoadedState([product]));
      }
    } catch (e) {
      log('❌ Failed to add to wishlist: $e');
    }
  }

  Future<void> clearWishlist() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final wishlistQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      for (var doc in wishlistQuery.docs) {
        await doc.reference.delete();
      }

      emit(const WishlistLoadedState([]));
    } catch (e) {
      log('❌ Failed to clear wishlist: $e');
    }
  }

  Future<bool> isInWishlist(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      log('❌ Failed to check wishlist: $e');
      return false;
    }
  }
  Future<void> removeFromWishlist(String productId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .where(FieldPath.documentId, isEqualTo: productId)
        .get();

    for (var d in doc.docs) {
      await d.reference.delete();
    }

    loadWishlist(); // 상태 갱신
  }

}
