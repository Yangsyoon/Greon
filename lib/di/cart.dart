// Feature: Cart
import '../application/cart_bloc/cart_bloc.dart';
import '../data/data_sources/local/cart_local_data_source.dart';
import '../data/data_sources/remote/cart_remote_data_source.dart';
import '../data/repositories/cart_repository_impl.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/usecases/cart/add_cart_item_usecase.dart';
import '../domain/usecases/cart/clear_cart_usecase.dart';
import '../domain/usecases/cart/get_cached_cart_usecase.dart';
import '../domain/usecases/cart/delete_cart_item_usecase.dart';
import '../domain/usecases/cart/sync_cart_usecase.dart';
import 'di.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


void registerCartFeature() {
  // Cart BLoC and Use Cases
  sl.registerFactory(
        () => CartBloc(sl(), sl(), sl(), sl(), sl(), sl(),),
  );
  // Use cases
  sl.registerLazySingleton(() => GetCachedCartUseCase(sl()));
  sl.registerLazySingleton(() => AddCartUseCase(sl()));
  sl.registerLazySingleton(() => SyncCartUseCase(sl()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCartItemUseCase(sl()));

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton(() => FirebaseAuth.instance);
  }


  // Repository
  sl.registerLazySingleton<CartRepository>(
        () => CartRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      userLocalDataSource: sl(),
    ),
  );
  // Data sources
  sl.registerLazySingleton<CartRemoteDataSource>(
        () => CartRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<CartLocalDataSource>(
        () => CartLocalDataSourceImpl(sharedPreferences: sl()),
  );

}