import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrescriptionCard extends StatelessWidget {
  const PrescriptionCard(
      {super.key,
      this.onDismissed,
      required this.dKey,
      required this.image,
      required this.doctorName,
      required this.date,
      required this.note,
      required this.drugs});

  final void Function(DismissDirection)? onDismissed;
  final Key dKey;
  final String image;
  final String doctorName;
  final DateTime date;
  final String note;
  final List<String> drugs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Dismissible(
        key: dKey,
        onDismissed: onDismissed,
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
            leading: CircleAvatar(
              radius: 50,
              foregroundImage: AssetImage(image),
            ),
            title: Text("dr.$doctorName"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('date : ${DateFormat.yMEd().format(date)}'),
                SingleChildScrollView(
                  scrollDirection: axisDirectionToAxis(AxisDirection.right),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Drugs:',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        ...drugs
                            .map(
                              (e) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(e)),
                            )
                            .toList(),
                      ]),
                )
              ],
            ),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
