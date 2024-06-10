import 'package:flutter/material.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/widgets/work_times.dart';
import 'package:intl/intl.dart';

class DcotorTabs extends StatefulWidget {
  DcotorTabs({super.key, required this.data}) {}
  final Map<String, dynamic> data;

  @override
  State<DcotorTabs> createState() => _DcotorTabsState();
}

class _DcotorTabsState extends State<DcotorTabs> {
  @override
  Widget build(BuildContext context) {
    List dates = widget.data['dates'];
    List texts = dates
        .map((e) => WorkTimes(
            day: e['dayName'].toString(),
            form: e['from'].toString(),
            to: e['to'].toString()))
        .toList();
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final decoration = BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: colors.primary.withAlpha(50));

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),

                  borderRadius: BorderRadius.circular(50), // Creates border
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBar(
                    dividerHeight: 0,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50), // Creates border
                    ),
                    tabs: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('About',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Adress',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Worktime',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: TabBarView(children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: decoration,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Univirsty: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              widget.data['collegeName'],
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Specialty: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              widget.data['departmentName'],
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Email: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              widget.data['email'],
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Joining date: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              DateFormat('yMd').format(
                                  DateTime.parse(widget.data['dateOfJoin'])),
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Gender: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              widget.data['gender'] ? 'Male' : 'Female',
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: decoration,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Adress: ',
                              style: textTheme.titleLarge!
                                  .copyWith(color: colors.primary),
                            ),
                            Text(
                              widget.data['addressDescrption'],
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: decoration,
                    child: Column(
                      children: [
                        ...texts,
                      ],
                    ),
                  )
                ]),
              ),
            ],
          ),
        ));
  }
}
