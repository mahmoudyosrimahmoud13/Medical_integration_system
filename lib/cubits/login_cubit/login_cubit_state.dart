part of 'login_cubit_cubit.dart';

abstract class LoginCubitState {}

final class LoginCubitInitial extends LoginCubitState {}

final class LoginCubitLoading extends LoginCubitState {}

final class LoginCubitFailed extends LoginCubitState {}

final class LoginCubitSuccess extends LoginCubitState {}
