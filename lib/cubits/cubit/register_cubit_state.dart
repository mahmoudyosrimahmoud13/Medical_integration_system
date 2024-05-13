part of 'register_cubit_cubit.dart';

abstract class RegisterStates {}

final class RegisterCubitInitial extends RegisterStates {}

final class RegisterCubitLoading extends RegisterStates {}

final class RegisterCubitFailed extends RegisterStates {}

final class RegisterCubitSuccess extends RegisterStates {}
