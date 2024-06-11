part of 'get_prescriptions_cubit.dart';

@immutable
sealed class GetPrescriptionsState {}

final class GetPrescriptionsInitial extends GetPrescriptionsState {}

final class GetPrescriptionsLoading extends GetPrescriptionsState {}

final class GetPrescriptionsSuccess extends GetPrescriptionsState {
  final List data;
  List cards = [];
  int index = 0;

  GetPrescriptionsSuccess({required this.data}) {
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    if (data.isNotEmpty) {
      cards = data.map((e) {
        index++;
        return PrescriptionCard(
            dKey: ValueKey(index),
            diseaseName: e['diseaseName'],
            doctorName: e['dcotorName'],
            date: e['date'],
            doctorImg: e['doctorImg'],
            doctorPhone: e['doctorEmail'],
            doctorEmail: e['doctorPhone'],
            index: index);
      }).toList();
    } else {
      cards = [
        Container(
            padding: EdgeInsets.all(50),
            child:
                Image(image: AssetImage('assets/placeholders/Empty-cuate.png')))
      ];
    }
  }
}

final class GetPrescriptionError extends GetPrescriptionsState {
  final String message;

  GetPrescriptionError({required this.message});
}
