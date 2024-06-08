import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class DrugCard extends StatelessWidget {
  const DrugCard(
      {super.key,
      required this.drugName,
      required this.repeate,
      required this.instructions,
      required this.startDate,
      required this.endDate});
  final String drugName;
  final String repeate;
  final String instructions;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final TextTheme = Theme.of(context).textTheme.bodyLarge;
    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/logo/logo_colores.png'),
                opacity: 0.2)),
        padding: EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drug name: ' + drugName,
              style: TextTheme,
            ),
            Text('Rpeate: ' + repeate, style: TextTheme),
            Text('Instructions: ' + instructions, style: TextTheme),
            Text('Start date: ' + DateFormat.yMEd().format(startDate),
                style: TextTheme),
            Text('End date: ' + DateFormat.yMEd().format(endDate),
                style: TextTheme),
            SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    );
  }
}
