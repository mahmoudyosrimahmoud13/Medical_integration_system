part of 'get_user_data_cubit.dart';

@immutable
sealed class GetUserDataState {}

final class GetUserDataInitial extends GetUserDataState {}

final class GetUserDataLoading extends GetUserDataState {}

final class GetUserDataSuccess extends GetUserDataState {
  final Map<String, dynamic> data;

  GetUserDataSuccess({required this.data}) {
    CacheHelper.saveData(key: 'name', value: data['name']);
  }
}

final class GetUserDataError extends GetUserDataState {
  final String message;

  GetUserDataError({required this.message});
}
