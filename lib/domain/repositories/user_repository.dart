import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user/app_user.dart';
import '../usecases/user/sign_in_usecase.dart';
import '../usecases/user/sign_up_usecase.dart';


abstract class UserRepository {
  Future<Either<Failure, AppUser>> signIn(SignInParams params);
  Future<Either<Failure, AppUser>> signUp(SignUpParams params);
  Future<Either<Failure, NoParams>> signOut();
  Future<Either<Failure, AppUser>> getCachedUser();
}
