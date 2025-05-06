import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/user/app_user.dart';
import '../../repositories/user_repository.dart';

class SignInUseCase implements UseCase<AppUser, SignInParams> {
  final UserRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(SignInParams params) async {
    return await repository.signIn(params);
  }
}

class SignInParams {
  final String username;
  final String password;
  const SignInParams({
    required this.username,
    required this.password,
  });
}