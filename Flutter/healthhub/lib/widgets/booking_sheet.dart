import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:healthhub/cubit/booking/booking_cubit.dart';
import 'package:intl/intl.dart';

class BookingSheet extends StatefulWidget {
  const BookingSheet({super.key, required this.id});
  final String id;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  TimeOfDay? _hour;
  DateTime? _day;
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: 100,
                width: 200,
                child: SvgPicture(
                    SvgAssetLoader('assets/placeholders/booking.svg'))),
            Text(
              'Book an appointment',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(_day == null
                    ? "Choose a date"
                    : DateFormat.yMd().format(_day!))
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                    helpText: 'Booking day');
                setState(() {
                  _day = value;
                });
              },
              child: Text(
                'Choose a day',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.alarm,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(_hour == null
                    ? "Choose an hour"
                    : DateFormat.jm()
                        .format(DateTime.now().copyWith(hour: _hour!.hour)))
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final value = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  helpText: 'Booking hour',
                );
                setState(() {
                  _hour = value;
                });
              },
              child: Text(
                'Choose a hour',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    if (_day != null && _hour != null) {
                      BlocProvider.of<BookingCubit>(context)
                          .book(id: widget.id, day: _day!, time: _hour!);
                    }
                  },
                  child: Text('Book')),
            )
          ],
        ));
  }
}
