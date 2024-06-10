import 'package:flutter/material.dart';

class WorkTimes extends StatelessWidget {
  const WorkTimes(
      {super.key, required this.day, required this.form, required this.to});
  final String day;
  final String form;
  final String to;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final primaryStyle = colors.primary;
    return Container(
      child: Card(
        child: ListTile(
          title: Row(
            children: [
              Text(
                'Day:',
                style: TextStyle(color: primaryStyle),
              ),
              Text(day),
            ],
          ),
          subtitle: Row(
            children: [
              Row(
                children: [
                  Text('From:', style: TextStyle(color: primaryStyle)),
                  Text(form),
                ],
              ),
              SizedBox(
                width: 20,
              ),
              Row(
                children: [
                  Text('To:', style: TextStyle(color: primaryStyle)),
                  Text(to),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
