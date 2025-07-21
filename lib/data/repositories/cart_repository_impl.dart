import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../core/networkchecker/network_info.dart';
import '../../domain/entities/cart/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../data_sources/local/cart_local_data_source.dart';
import '../data_sources/local/user_local_data_source.dart';
import '../data_sources/remote/cart_remote_data_source.dart';
import '../models/cart/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final UserLocalDataSource userLocalDataSource;
  final NetworkInfo networkInfo;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.userLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CartItem>>> getCartFromFirestore() async {
    try {
      final cartModelsResult = await remoteDataSource.getCartFromFirestore();
      return cartModelsResult.fold(
            (failure) => Left(failure),
            (cartModels) => Right(cartModels.map((e) => e.toDomain()).toList()),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartItem>> addToCart(CartItem cartItem) async {
    print("CartRepositoryImpl: addToCart 호출");
    try {
      // 항상 로컬 저장
      await localDataSource.saveCartItem(CartItemModel.fromParent(cartItem));

      // 토큰이 있으면 remote도 호출
      String token;
      try {
        token = await userLocalDataSource.getToken();
      } catch (e) {
        // 토큰이 없을 때의 처리
        return Left(AuthenticationFailure(message: 'User token not found'));
      }
      if (token != null && token.isNotEmpty) {
        final remoteResult = await remoteDataSource.addToCart(
          CartItemModel.fromParent(cartItem),
          token,
        );
        print("CartRepositoryImpl: remote addToCart 호출");
        return remoteResult.fold(
              (failure) => Left(failure),
              (cartItemModel) => Right(cartItemModel.toDomain()),
        );
      } else {
        print("CartRepositoryImpl: 토큰 없음, 로컬 저장만");
        return Right(cartItem);
      }
    } catch (e) {
      print('CartRepositoryImpl addToCart error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> getCachedCart() async {
    try {
      final localProducts = await localDataSource.getCart();
      return Right(localProducts.map((e) => e.toDomain()).toList());
    } catch (failure) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> syncCart() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }
    String token;
    try {
      token = await userLocalDataSource.getToken();
    } catch (e) {
      // 토큰이 없을 때의 처리
      return Left(AuthenticationFailure(message: 'User token not found'));
    }
    try {
      final List<CartItemModel> localCartItems = await localDataSource.getCart();
      final syncedResult = await remoteDataSource.syncCart(localCartItems, token);
      return syncedResult.fold(
            (failure) => Left(failure),
            (cartModels) async {
          await localDataSource.saveCart(cartModels);
          return Right(cartModels.map((e) => e.toDomain()).toList());
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearCart() async {
    try {
      bool result = await localDataSource.clearCart();
      if (result) {
        return Right(result);
      } else {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFormCart() {
    // TODO: implement deleteFormCart
    throw UnimplementedError();
  }

  @override
  Future<void> updateCartItem(CartItem cartItem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final userId = user.uid;

    if (cartItem.id == null) {
      throw Exception("Cart item ID is null, can't update");
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(cartItem.id)
        .update({'quantity': cartItem.quantity});
  }

  @override
  Future<Either<Failure, void>> deleteCartItem(String itemId) {
    return remoteDataSource.deleteCartItem(itemId);
  }

}
