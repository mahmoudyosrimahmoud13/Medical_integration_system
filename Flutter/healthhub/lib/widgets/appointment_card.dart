import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/get_appointments/get_appointments_cubit.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard(
      {super.key,
      required this.dKey,
      required this.name,
      required this.startDate,
      required this.endDate,
      required this.date,
      required this.doctorSpecialty,
      required this.areaName,
      required this.governorateName,
      required this.dayName,
      required this.id});

  final Key dKey;
  final String id;
  final String name;
  final String doctorSpecialty;
  final String areaName;
  final String governorateName;
  final String date;
  final String dayName;
  final String startDate;
  final String endDate;

  @override
  Widget build(BuildContext context) {
    print(id);
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Dismissible(
        key: dKey,
        onDismissed: (direction) {
          BlocProvider.of<GetAppointmentsCubit>(context).cancel(id: id);
        },
        direction: DismissDirection.endToStart,
        background: Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onError,
                ),
              )
            ],
          ),
          color: Theme.of(context).colorScheme.error,
        ),
        child: Card(
          child: ListTile(
            title: Text("dr.$name"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Specialty : $doctorSpecialty'),
                Text('Governoate : $governorateName'),
                Text('Area : $areaName'),
                Text('Day : $dayName'),
                Text('date : $date'),
                Text('From : $endDate'),
                Text('To : $endDate'),
              ],
            ),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
