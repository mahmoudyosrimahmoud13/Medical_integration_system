import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class DrugCard extends StatelessWidget {
  const DrugCard({
    super.key,
    required this.drugName,
    required this.repeat,
    required this.repeatCount,
    required this.note,
    required this.startdate,
    required this.enddate,
  });
  final String drugName;
  final String repeat;
  final String repeatCount;
  final String note;
  final String startdate;
  final String enddate;

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
            Text('Drug name: ' + drugName, style: TextTheme),
            Text('Rpeate: ' + repeat, style: TextTheme),
            Text('Rpeate count: ' + repeatCount, style: TextTheme),
            Text('Note: ' + note, style: TextTheme),
            Text('Start date: ' + startdate, style: TextTheme),
            Text('End date: ' + enddate, style: TextTheme),
            SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    );
  }
}
