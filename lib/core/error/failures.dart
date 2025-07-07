import 'package:equatable/equatable.dart';
class AuthFailure extends Failure {
  AuthFailure({required String message}) : super(message: message);
}


abstract class Failure extends Equatable {
  final String? message;

  const Failure({this.message});

  @override
  List<Object?> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({String? message}) : super(message: message ?? "서버 오류 발생");

  @override
  String toString() => "ServerFailure: $message";
}

class PermissionFailure extends Failure {
  const PermissionFailure({String? message}) : super(message: message ?? 'Permission denied');

  @override
  String toString() => "PermissionFailure: $message";
}

class CacheFailure extends Failure {
  const CacheFailure({String? message}) : super(message: message ?? 'Cache failure');

  @override
  String toString() => "CacheFailure: $message";
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message}) : super(message: message ?? 'Network failure');

  @override
  String toString() => "NetworkFailure: $message";
}

class ExceptionFailure extends Failure {
  const ExceptionFailure({String? message}) : super(message: message ?? 'Exception occurred');

  @override
  String toString() => "ExceptionFailure: $message";
}

class CredentialFailure extends Failure {
  const CredentialFailure({String? message}) : super(message: message ?? 'Credential failure');

  @override
  String toString() => "CredentialFailure: $message";
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({String? message}) : super(message: message ?? 'Authentication failure');

  @override
  String toString() => "AuthenticationFailure: $message";
}
