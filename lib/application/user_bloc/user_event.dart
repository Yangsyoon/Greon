part of 'user_bloc.dart';

@immutable
abstract class UserEvent {}

class SignInUser extends UserEvent {
  final SignInParams params;
  SignInUser(this.params);
}

class SignUpUser extends UserEvent {
  final SignUpParams params;
  SignUpUser(this.params);
}

class SignOutUser extends UserEvent {}

class CheckUser extends UserEvent {}

// user_event.dart 수정
class EmitUserLogged extends UserEvent {
  final AppUser appUser;  // AppUser 타입으로 변경

  EmitUserLogged(this.appUser);
}

class EmitUserUnlogged extends UserEvent {}  // 로그아웃 상태를 명시적으로 표현



