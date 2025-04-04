// Feature: Product
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../application/products_bloc/product_bloc.dart';
import '../data/data_sources/local/product_local_data_source.dart';
import '../data/data_sources/remote/product_remote_data_source.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/product/get_product_usecase.dart';
import 'di.dart';

void registerProductFeature() {
  // Product BLoC and Use Cases
  if (!sl.isRegistered<ProductBloc>()) {
    sl.registerFactory(() => ProductBloc(sl()));
  }

  if (!sl.isRegistered<GetProductUseCase>()) {
    sl.registerLazySingleton(() => GetProductUseCase(sl()));
  }

  // Product Repository and Data Sources
  if (!sl.isRegistered<ProductRepository>()) {
    sl.registerLazySingleton<ProductRepository>(
          () => ProductRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  if (!sl.isRegistered<ProductRemoteDataSource>()) {
    sl.registerLazySingleton<ProductRemoteDataSource>(
          () => ProductRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>(), client: sl()),
    );
  }

  if (!sl.isRegistered<ProductLocalDataSource>()) {
    sl.registerLazySingleton<ProductLocalDataSource>(
          () => ProductLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }
}
