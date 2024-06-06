part of 'adress_cubit.dart';

@immutable
sealed class AdressState {}

final class AdressInitial extends AdressState {}

final class AdressLoading extends AdressState {}

final class AdressSucsses extends AdressState {
  AdressSucsses({required this.data, required this.key}) {
    print(data[0]);
    governrates = data.map(
      (e) {
        return DropdownMenuItem<String>(
          value: e['key'],
          child: Text(e['key']),
        );
      },
    ).toList();
    governrates.insert(
        0,
        const DropdownMenuItem(
            value: 'Choose Governrate',
            child: Text(
              'Choose Governrate',
            )));
    print(key);
    areas = key.map(
      (e) {
        return DropdownMenuItem<String>(
          value: e['key'],
          child: Text(e['key']),
        );
      },
    ).toList();
    areas.insert(
        0,
        const DropdownMenuItem(
            value: 'Choose area',
            child: Text(
              'Choose area',
            )));
  }

  final List<dynamic> data;
  final List<dynamic> key;
  List<DropdownMenuItem<String>> governrates = [];
  List<DropdownMenuItem<String>> areas = [];
}

final class AdressError extends AdressState {
  final String error;

  AdressError({required this.error});
}
