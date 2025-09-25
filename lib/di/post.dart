// lib/di/post.dart

import 'package:get_it/get_it.dart';
import '../data/data_sources/remote/post_remote_data_source.dart'; // 실제 경로에 맞게 수정
import '../data/repositories/post_repository.dart'; // 실제 경로에 맞게 수정

final sl = GetIt.instance;

void registerPostFeature() {
  // Repository
  // PostRepositoryImpl은 PostRepository의 구현체라고 가정합니다.
  sl.registerLazySingleton<PostRepository>(
        () => PostRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  // PostRemoteDataSourceImpl은 PostRemoteDataSource의 구현체라고 가정합니다.
  sl.registerLazySingleton<PostRemoteDataSource>(
        () => PostRemoteDataSourceImpl(firestore: sl()),
  );
}