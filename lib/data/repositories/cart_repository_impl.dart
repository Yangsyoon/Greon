  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
  
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
        final cartModels = await remoteDataSource.getCartFromFirestore();
        final cartItems = cartModels.map((e) => e as CartItem).toList();
        return Right(cartItems);
      } on FirebaseException catch (e) {
        // 예시: 권한 문제, 네트워크 문제 등 코드별로 분기
        if (e.code == 'permission-denied') {
          return Left(PermissionFailure());
        } else if (e.code == 'unavailable') {
          return Left(NetworkFailure());
        }
        return Left(ServerFailure(message: e.message ?? 'Unknown error'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    }



    @override
    Future<Either<Failure, CartItem>> addToCart(CartItem params) async {
      try{if (await userLocalDataSource.isTokenAvailable()) {
        await localDataSource.saveCartItem(CartItemModel.fromParent(params));
        final String token = await userLocalDataSource.getToken();
        final remoteProduct = await remoteDataSource.addToCart(
          CartItemModel.fromParent(params),
          token,
        );
        return Right(remoteProduct);
      } else {
        await localDataSource.saveCartItem(CartItemModel.fromParent(params));
        return Right(params);
      }}catch(e)
      {
        print('CartRepositoryImpl addToCart error: $e');
        return Left(ServerFailure(message: e.toString()));
      }

    }
  
    @override
    Future<Either<Failure, bool>> deleteFormCart() {
      // TODO: implement deleteFormCart
      throw UnimplementedError();
    }
  
    @override
    Future<Either<Failure, List<CartItem>>> getCachedCart() async {
      try {
        final localProducts = await localDataSource.getCart();
        return Right(localProducts);
      } on Failure catch (failure) {
        return Left(failure);
      }
    }
  
    @override
    Future<Either<Failure, List<CartItem>>> syncCart() async {
      if (await networkInfo.isConnected) {
        if (await userLocalDataSource.isTokenAvailable()) {
          List<CartItemModel> localCartItems = [];
          try {
            localCartItems = await localDataSource.getCart();
          } on Failure catch (_) {}
          try {
            final String token = await userLocalDataSource.getToken();
            final syncedResult = await remoteDataSource.syncCart(
              localCartItems,
              token,
            );
            await localDataSource.saveCart(syncedResult);
            return Right(syncedResult);
          } on Failure catch (failure) {
            return Left(failure);
          }
        } else {
          return Left(NetworkFailure());
        }
      } else {
        return Left(NetworkFailure());
      }
    }
  
    @override
    Future<Either<Failure, bool>> clearCart() async {
      bool result = await localDataSource.clearCart();
      if (result) {
        return Right(result);
      } else {
        return Left(CacheFailure());
      }
    }
  }
