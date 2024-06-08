part of 'authentication_cubit.dart';

@immutable
sealed class AuthenticationState {}

final class AuthenticationInitial extends AuthenticationState {}

final class AuthenticationLoading extends AuthenticationState {}

final class AuthenticationSuccess extends AuthenticationState {
  final String? message;

  AuthenticationSuccess({required this.message});
}

final class AuthenticationError extends AuthenticationState {
  final String error;

  AuthenticationError({required this.error});
}
