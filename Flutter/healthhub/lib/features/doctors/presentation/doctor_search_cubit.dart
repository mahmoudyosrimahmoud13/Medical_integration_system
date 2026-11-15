import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../domain/doctors.dart';

class DoctorSearchState extends Equatable {
  const DoctorSearchState({
    this.filter = const DoctorFilter(),
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  final DoctorFilter filter;
  final List<DoctorSummary> items;
  final int total;
  final int page;
  final bool loading;
  final bool loadingMore;
  final String? error;

  bool get hasMore => items.length < total;

  DoctorSearchState copyWith({
    DoctorFilter? filter,
    List<DoctorSummary>? items,
    int? total,
    int? page,
    bool? loading,
    bool? loadingMore,
    String? Function()? error,
  }) =>
      DoctorSearchState(
        filter: filter ?? this.filter,
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props => [filter, items, total, page, loading, loadingMore, error];
}

/// Doctor search with filters and "load more" paging.
/// Typing a name waits briefly before searching, so each key press doesn't hit the server.
class DoctorSearchCubit extends Cubit<DoctorSearchState> {
  DoctorSearchCubit(this._repo, {DoctorFilter initial = const DoctorFilter(), this.debounce = const Duration(milliseconds: 350)})
      : super(DoctorSearchState(filter: initial));

  final DoctorRepository _repo;
  final Duration debounce;
  Timer? _timer;
  int _request = 0;

  Future<void> search() async {
    final id = ++_request;
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final page = await _repo.search(state.filter);
      if (isClosed || id != _request) return; // a newer search started
      emit(state.copyWith(items: page.items, total: page.total, page: 0, loading: false));
    } on ApiException catch (e) {
      if (isClosed || id != _request) return;
      emit(state.copyWith(loading: false, error: () => e.message));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repo.search(state.filter, page: state.page + 1);
      if (isClosed) return;
      emit(state.copyWith(items: [...state.items, ...next.items], total: next.total, page: state.page + 1, loadingMore: false));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadingMore: false, error: () => e.message));
    }
  }

  void setSpecialty(String? id) => _update(state.filter.copyWith(specialtyId: () => id));

  void setLocation(String? governorateId, String? areaId) =>
      _update(state.filter.copyWith(governorateId: () => governorateId, areaId: () => areaId));

  void setSort(DoctorSort sort) => _update(state.filter.copyWith(sort: sort));

  void setName(String name) {
    emit(state.copyWith(filter: state.filter.copyWith(name: () => name.trim().isEmpty ? null : name.trim())));
    _timer?.cancel();
    _timer = Timer(debounce, search);
  }

  void _update(DoctorFilter f) {
    emit(state.copyWith(filter: f));
    search();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
