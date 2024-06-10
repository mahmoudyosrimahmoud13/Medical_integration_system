part of 'area_cubit.dart';

@immutable
sealed class AreaState {}

final class AreaInitial extends AreaState {}

final class AreaLoading extends AreaState {}

final class AreaSuccess extends AreaState {
  final List<dynamic> data;
  List<DropdownMenuItem<int>> areas = [];
  int index = -1;

  AreaSuccess({required this.data}) {
    areas = data.map(
      (e) {
        index++;
        return DropdownMenuItem<int>(
          value: index,
          child: Text(e['key']),
        );
      },
    ).toList();
    areas.insert(
        0,
        const DropdownMenuItem(
            value: 10000,
            child: Text(
              'Choose area',
            )));
  }
}

final class AreaError extends AreaState {
  final String error;

  AreaError({required this.error});
}
