import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/user/app_user.dart';
import '../../repositories/user_repository.dart';

class GetCachedUserUseCase implements UseCase<AppUser, NoParams> {
  final UserRepository repository;
  GetCachedUserUseCase(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) async {
    return await repository.getCachedUser();
  }
}
