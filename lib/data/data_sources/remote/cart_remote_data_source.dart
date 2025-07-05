import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cart/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<CartItemModel> addToCart(CartItemModel cartItem, String token);
  Future<List<CartItemModel>> syncCart(List<CartItemModel> cart, String token);
  Future<List<CartItemModel>> getCartFromFirestore();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CartRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<List<CartItemModel>> getCartFromFirestore() async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final cartCollection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final snapshot = await cartCollection.get();
      return snapshot.docs
          .map((doc) => CartItemModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error: $e');
      rethrow;
    }
  }

  @override
  Future<CartItemModel> addToCart(CartItemModel cartItem, String token) async {
    final user = auth.currentUser;
    if (user == null) {
      print('User not logged in');
      throw Exception('User not logged in');
    }
    print('Saving to Firestore: ${cartItem.toJson()}');
    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add(cartItem.toJson());
      print('Saved!');
      return cartItem;
    } catch (e) {
      print('Firestore addToCart error: $e');
      rethrow;
    }
  }

  @override
  Future<List<CartItemModel>> syncCart(List<CartItemModel> cart, String token) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final cartCollection = firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final batch = firestore.batch();
    final snapshot = await cartCollection.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    for (final cartItem in cart) {
      await cartCollection.add(cartItem.toJson());
    }

    final newSnapshot = await cartCollection.get();
    return newSnapshot.docs
        .map((doc) => CartItemModel.fromJson(doc.data()))
        .toList();
  }
}
