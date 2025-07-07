import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/error/failures.dart';
import '../../models/cart/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<Either<Failure, CartItemModel>> addToCart(CartItemModel cartItem, String token);
  Future<Either<Failure, List<CartItemModel>>> syncCart(List<CartItemModel> cart, String token);
  Future<Either<Failure, List<CartItemModel>>> getCartFromFirestore();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CartRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  @override
  Future<Either<Failure, List<CartItemModel>>> getCartFromFirestore() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        return Left(AuthenticationFailure(message: 'User not logged in'));
      }
      final cartCollection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final snapshot = await cartCollection.get();
      final cartItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItemModel.fromJson(data).copyWith(id: doc.id); // 🔑 id 추가
      }).toList();

      return Right(cartItems);
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.code} - ${e.message}');
      return Left(ServerFailure(message: e.message ?? e.code));
    } catch (e) {
      print('Unknown error: $e');
      return Left(ExceptionFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartItemModel>> addToCart(CartItemModel cartItem,
      String token) async {
    final user = auth.currentUser;
    print('firebase 용 addtocart 호출! Saving to Firestore: ${cartItem.toJson()}');
    if (user == null) {
      print('User not logged in');
      return Left(AuthenticationFailure(message: 'User not logged in'));
    }
    try {
      final docRef = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add(cartItem.toJson());
      print('Saved! Document ID: ${docRef.id}');
      // id를 반영해서 반환
      return Right(cartItem.copyWith(id: docRef.id));
    } on FirebaseException catch (e) {
      print('Firestore addToCart error: ${e.code} - ${e.message}');
      return Left(ServerFailure(message: e.message ?? e.code));
    } catch (e) {
      print('Firestore addToCart error: $e');
      return Left(ExceptionFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CartItemModel>>> syncCart(
      List<CartItemModel> cart, String token) async {
    final user = auth.currentUser;
    if (user == null) {
      return Left(AuthenticationFailure(message: 'User not logged in'));
    }
    try {
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
        final docRef = cartCollection.doc(); // 문서 ID 미리 생성
        final newCartItem = cartItem.copyWith(id: docRef.id); // ← id 포함된 객체 만들기
        await docRef.set(newCartItem.toJson());
      }

      final newSnapshot = await cartCollection.get();
      final resultList = newSnapshot.docs
          .map((doc) => CartItemModel.fromJson(doc.data()))
          .toList();

      return Right(resultList);
    } on FirebaseException catch (e) {
      print('Firestore syncCart error: ${e.code} - ${e.message}');
      return Left(ServerFailure(message: e.message ?? e.code));
    } catch (e) {
      print('Unknown syncCart error: $e');
      return Left(ExceptionFailure(message: e.toString()));
    }
  }
}
