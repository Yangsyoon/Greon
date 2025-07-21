import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/error/failures.dart';
import '../../models/cart/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<Either<Failure, CartItemModel>> addToCart(CartItemModel cartItem, String token);
  Future<Either<Failure, List<CartItemModel>>> syncCart(List<CartItemModel> cart, String token);
  Future<Either<Failure, List<CartItemModel>>> getCartFromFirestore();
  Future<Either<Failure, void>> deleteCartItem(String itemId);
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

      final cartItems = snapshot.docs
          .map((doc) => CartItemModel.fromDocument(doc))
          .toList();

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
  Future<Either<Failure, CartItemModel>> addToCart(
      CartItemModel cartItem, String token) async {
    final user = auth.currentUser;
    if (user == null) {
      print('User not logged in');
      return Left(AuthenticationFailure(message: 'User not logged in'));
    }

    try {
      final cartRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      print('🧪 productId for search: ${cartItem.product.id}');
      final allDocs = await cartRef.get();
      print('🧪 전체 장바구니 아이템 수: ${allDocs.docs.length}');
      // productId 기준으로 기존 아이템 있는지 확인
      final querySnapshot = await cartRef
          .where('productId', isEqualTo: cartItem.productId)
          .limit(1)
          .get();

      print('Firestore 비교용 productId = ${cartItem.product.id}');
      print('기존 장바구니 아이템 수: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        // 이미 장바구니에 있음 -> quantity 증가
        final existingDoc = querySnapshot.docs.first;
        final existingData = existingDoc.data();
        final existingQuantity = (existingData['quantity'] ?? 1) as int;
        final newQuantity = existingQuantity + cartItem.quantity;

        await cartRef.doc(existingDoc.id).update({
          'quantity': newQuantity,
          // 필요시 다른 필드도 업데이트
        });

        return Right(cartItem.copyWith(
          id: existingDoc.id,
          quantity: newQuantity,
        ));
      } else {
        // 새로 추가
        final docRef = await cartRef.add(cartItem.toJson());
        return Right(cartItem.copyWith(id: docRef.id));
      }
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
  @override
  Future<Either<Failure, void>> deleteCartItem(String itemId) async {
    final user = auth.currentUser;
    if (user == null) {
      return Left(AuthenticationFailure(message: 'User not logged in'));
    }

    try {
      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);

      await docRef.delete();
      print('🗑️ Deleted cart item with id: $itemId');
      return Right(null);
    } on FirebaseException catch (e) {
      print('Firestore delete error: ${e.code} - ${e.message}');
      return Left(ServerFailure(message: e.message ?? e.code));
    } catch (e) {
      print('Unknown delete error: $e');
      return Left(ExceptionFailure(message: e.toString()));
    }
  }

}
