import 'package:flutter/material.dart';
import 'package:healthhub/widgets/appointment_card.dart';
import 'package:intl/intl.dart';

class appointmentScreen extends StatefulWidget {
  const appointmentScreen({super.key, required this.name, required this.url});
  final String name;
  final String url;

  @override
  State<appointmentScreen> createState() => _appointmentScreenState();
}

class _appointmentScreenState extends State<appointmentScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
          child: Column(
        children: [
          SizedBox(
            height: size.height * 0.17,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // user name:
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(widget.url),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Hi, ${widget.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          // Date:
                          Text(
                            DateFormat.yMMMd().format(DateTime.now()),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withAlpha(200),
                            ),
                          ),
                        ],
                      )
                      //Notification bell
                      ,
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(150),
                        ),
                        child: IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
          // Body
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Your appointments',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
                  child: Divider(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                AppointmentCard(
                  dKey: ValueKey(''),
                  image:
                      'assets/placeholders/pngtree-male-doctor-avatar-icon-illustration-png-image_8537702.png',
                  name: 'Sara',
                  date: DateTime.now(),
                  startDate: DateTime.now(),
                  endDate: DateTime.now(),
                ),
              ],
            ),
          ))
        ],
      )),
    );
  }
}
