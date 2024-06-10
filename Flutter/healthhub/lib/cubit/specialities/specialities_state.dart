part of 'specialities_cubit.dart';

@immutable
sealed class SpecialitiesState {}

final class SpecialitiesInitial extends SpecialitiesState {}

final class SpecialitiesLoading extends SpecialitiesState {}

final class SpecialitiesSuccess extends SpecialitiesState {
  final List<dynamic> data;
  List<DropdownMenuItem<int>> specialities = [];
  int index = -1;

  SpecialitiesSuccess({required this.data}) {
    specialities = data.map(
      (e) {
        index++;
        return DropdownMenuItem<int>(
          value: index,
          child: Text(e['name']),
        );
      },
    ).toList();
    specialities.insert(
        0,
        const DropdownMenuItem(
            value: 10000,
            child: Text(
              'Choose Speciality',
            )));
  }
}

final class SpecialitiesError extends SpecialitiesState {
  final String error;

  SpecialitiesError({required this.error});
}
