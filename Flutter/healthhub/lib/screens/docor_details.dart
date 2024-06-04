import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:healthhub/widgets/doctor_tabs.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  void _showBookModalSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Scaffold(
        body: Container(
          child: YearPicker(
            firstDate: DateTime(2002),
            lastDate: DateTime(2002),
            selectedDate: DateTime.now(),
            onChanged: (value) {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: size.height * 0.3,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25))),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      // Doctor image
                      const CircleAvatar(
                        radius: 70,
                        backgroundImage: AssetImage(
                            'assets/placeholders/pngtree-male-doctor-avatar-icon-illustration-png-image_8537702.png'),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      RatingBar.builder(
                        initialRating: 4.5,
                        allowHalfRating: true,
                        ignoreGestures: true,
                        itemSize: 20,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (value) {},
                      )
                    ],
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  // Docotr data
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(
                      //   height: 25,
                      // ),
                      Text(
                        'dr.doctor',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      Text('Specialty: null',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              )),
                      Text('City: Alexandria',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              )),
                      Text('Phone: 01xxxxxxxx',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              )),
                    ],
                  )
                ],
              ),
            ),
          ),
          const Expanded(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: DcotorTabs(),
          )),
          Container(
            margin: const EdgeInsets.all(5),
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showBookModalSheet,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text(
                'Book an appointment',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          )
        ],
      ),
    );
  }
}
