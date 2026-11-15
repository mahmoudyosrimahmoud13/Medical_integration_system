import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_exception.dart';

enum LoadStatus { initial, loading, success, failure }

/// State for any screen that loads one thing: a list, a profile, a record.
class LoadState<T> extends Equatable {
  const LoadState({this.status = LoadStatus.initial, this.data, this.error});

  final LoadStatus status;
  final T? data;
  final String? error;

  bool get isLoading => status == LoadStatus.loading;
  bool get hasData => data != null;

  LoadState<T> copyWith({LoadStatus? status, T? data, String? error}) =>
      LoadState<T>(status: status ?? this.status, data: data ?? this.data, error: error);

  @override
  List<Object?> get props => [status, data, error];
}

/// A cubit that runs one loader function and exposes loading / data / error.
/// Most screens only need this; complex flows get their own cubit.
class LoadCubit<T> extends Cubit<LoadState<T>> {
  LoadCubit(this._loader, {bool autoLoad = true}) : super(LoadState<T>()) {
    if (autoLoad) load();
  }

  final Future<T> Function() _loader;

  Future<void> load() async {
    // Keep showing old data while refreshing, so the screen doesn't flash.
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final data = await _loader();
      if (isClosed) return;
      emit(LoadState<T>(status: LoadStatus.success, data: data));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(LoadState<T>(status: LoadStatus.failure, data: state.data, error: e.message));
    } catch (e) {
      if (isClosed) return;
      emit(LoadState<T>(status: LoadStatus.failure, data: state.data, error: 'Something went wrong. Please try again.'));
    }
  }
}

/// Runs one action (save, delete, book) and reports busy / done / error.
class ActionState extends Equatable {
  const ActionState({this.busy = false, this.error, this.doneCount = 0, this.message});

  final bool busy;
  final String? error;
  final int doneCount; // goes up by one after each success, so listeners can react
  final String? message;

  @override
  List<Object?> get props => [busy, error, doneCount, message];
}

class ActionCubit extends Cubit<ActionState> {
  ActionCubit() : super(const ActionState());

  Future<R?> run<R>(Future<R> Function() action, {String? successMessage}) async {
    if (state.busy) return null;
    emit(ActionState(busy: true, doneCount: state.doneCount));
    try {
      final result = await action();
      if (!isClosed) emit(ActionState(doneCount: state.doneCount + 1, message: successMessage));
      return result;
    } on ApiException catch (e) {
      if (!isClosed) emit(ActionState(error: e.message, doneCount: state.doneCount));
    } catch (_) {
      if (!isClosed) emit(ActionState(error: 'Something went wrong. Please try again.', doneCount: state.doneCount));
    }
    return null;
  }
}
