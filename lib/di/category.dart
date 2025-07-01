// Feature: Category
import 'package:cloud_firestore/cloud_firestore.dart';
import '../application/categories_bloc/category_bloc.dart';
import '../data/data_sources/local/category_local_data_source.dart';
import '../data/data_sources/remote/category_remote_data_source.dart';
import '../data/repositories/categories_repository_impl.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/usecases/category/filter_category_usecase.dart';
import '../domain/usecases/category/get_cached_category_usecase.dart';
import '../domain/usecases/category/get_remote_category_usecase.dart';
import 'di.dart';

void registerCategoryFeature() {
  // ✅ BLoC 중복 등록 방지
  if (!sl.isRegistered<CategoryBloc>()) {
    sl.registerFactory(() => CategoryBloc(sl(), sl(), sl()));
  }

  // ✅ UseCase 등록 중복 방지
  if (!sl.isRegistered<GetRemoteCategoryUseCase>()) {
    sl.registerLazySingleton(() => GetRemoteCategoryUseCase(sl()));
  }
  if (!sl.isRegistered<GetCachedCategoryUseCase>()) {
    sl.registerLazySingleton(() => GetCachedCategoryUseCase(sl()));
  }
  if (!sl.isRegistered<FilterCategoryUseCase>()) {
    sl.registerLazySingleton(() => FilterCategoryUseCase(sl()));
  }

  // ✅ Repository 등록 중복 방지
  if (!sl.isRegistered<CategoryRepository>()) {
    sl.registerLazySingleton<CategoryRepository>(
          () => CategoryRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // ✅ DataSource 등록 중복 방지
  if (!sl.isRegistered<CategoryRemoteDataSource>()) {
    sl.registerLazySingleton<CategoryRemoteDataSource>(
          () => CategoryRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
    );
  }

  if (!sl.isRegistered<CategoryLocalDataSource>()) {
    sl.registerLazySingleton<CategoryLocalDataSource>(
          () => CategoryLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }
}
