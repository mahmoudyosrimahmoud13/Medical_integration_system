part of 'governrates_cubit.dart';

@immutable
sealed class GovernratesState {}

final class GovernratesInitial extends GovernratesState {}

final class GovernratesLoading extends GovernratesState {}

final class GovernratesSuccess extends GovernratesState {
  final List<dynamic> data;
  List<DropdownMenuItem<int>> governrates = [];
  int index = -1;

  GovernratesSuccess({required this.data}) {
    governrates = data.map(
      (e) {
        index++;

        return DropdownMenuItem<int>(
          value: index,
          child: Text(e['key']),
        );
      },
    ).toList();
    governrates.insert(
        0,
        const DropdownMenuItem(
            value: 10000,
            child: Text(
              'Choose governrate',
            )));
  }
}

final class GovernratesError extends GovernratesState {
  final String error;

  GovernratesError({required this.error});
}
