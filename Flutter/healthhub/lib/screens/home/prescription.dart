import 'package:flutter/material.dart';
import 'package:healthhub/widgets/doctor_card.dart';
import 'package:healthhub/widgets/generic_texfield.dart';
import 'package:intl/intl.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  void _show_modal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 400,
          width: double.infinity,
          child: DoctorCard(),
        );
      },
    );
  }

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
                          Text(
                            'Hi, User.',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold),
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

                  // search Bar

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
                  'Your Prescription',
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
                DoctorCard(),
              ],
            ),
          ))
        ],
      )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: CircleBorder(),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () {},
      ),
    );
  }
}
