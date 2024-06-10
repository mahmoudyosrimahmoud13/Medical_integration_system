import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:healthhub/cubit/get_doctor/get_doctor_cubit.dart';
import 'package:healthhub/screens/loading_screen.dart';
import 'package:healthhub/widgets/booking_sheet.dart';
import 'package:healthhub/widgets/doctor_tabs.dart';
import 'package:intl/intl.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  TimeOfDay? _hour;
  DateTime? _day;

  void _showBookModalSheet() {
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        builder: (context) => BookingSheet(
              id: widget.id,
            ));
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<GetDoctorCubit>(context).getDoctor(id: widget.id);
    final size = MediaQuery.of(context).size;
    return BlocBuilder<GetDoctorCubit, GetDoctorState>(
      builder: (context, state) {
        if (state is GetDoctorSuccess) {
          final data = state.data;

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
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: NetworkImage(data['drImg']),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            RatingBar.builder(
                              initialRating: data['rate'] + 0.0,
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
                              'dr.${data['name']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                            ),

                            Text('Area: ${data['area']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    )),
                            Text('Phone: 0100000000',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    )),
                            Text('Univirsty: ${data['collegeName']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    )),
                            Text('Specialty: ${data['departmentName']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    )),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DcotorTabs(
                    data: data,
                  ),
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
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                )
              ],
            ),
          );
        } else {
          return const LoadingScreen();
        }
      },
    );
  }
}
