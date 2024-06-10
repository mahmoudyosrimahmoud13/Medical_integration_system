part of 'get_appointments_cubit.dart';

@immutable
sealed class GetAppointmentsState {}

final class GetAppointmentsInitial extends GetAppointmentsState {}

final class GetAppointmentsLoading extends GetAppointmentsState {}

final class GetAppointmentsDelete extends GetAppointmentsState {
  final bool success;

  GetAppointmentsDelete({required this.success}) {
    if (success) {
      showMessage(message: 'Canceled succesfully');
    } else {
      showMessage(message: 'Error', type: MessageType.faild);
    }
  }
}

final class GetAppointmentsSuccess extends GetAppointmentsState {
  final List data;
  List cards = [];

  GetAppointmentsSuccess({required this.data}) {
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    if (data.isNotEmpty) {
      cards = data
          .map(
            (e) => AppointmentCard(
                dKey: ValueKey(e['doctorId']),
                id: e['paientDateId'],
                name: e['doctorName'].toString(),
                startDate: e['from'].toString(),
                endDate: e['to'].toString(),
                date: e['date'].toString(),
                doctorSpecialty: e['doctorSpecialty'].toString(),
                areaName: e['areaName'].toString(),
                governorateName: e['governorateName'].toString(),
                dayName: e['dayName'].toString()),
          )
          .toList();
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

final class GetAppointmentsError extends GetAppointmentsState {
  final String message;

  GetAppointmentsError({required this.message});
}
