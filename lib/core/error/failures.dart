import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

// General failures
class ServerFailure extends Failure {
  final String message; // 메시지 필드 추가

  ServerFailure({this.message = "서버 오류 발생"}); // 기본값 설정

  @override
  String toString() => "ServerFailure: $message";
}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

class ExceptionFailure extends Failure {}

class CredentialFailure extends Failure {}

class AuthenticationFailure extends Failure {}
