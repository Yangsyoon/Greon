import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/user/app_user.dart';
import '../../repositories/user_repository.dart';

class SignUpUseCase implements UseCase<AppUser, SignUpParams> {
  final UserRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(SignUpParams params) async {
    return await repository.signUp(params);
  }
}

class SignUpParams {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  const SignUpParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });
}
