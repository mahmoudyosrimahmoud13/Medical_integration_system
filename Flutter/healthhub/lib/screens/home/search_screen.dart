import 'package:flutter/material.dart';
import 'package:healthhub/widgets/doctor_card.dart';
import 'package:healthhub/widgets/generic_texfield.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
              height: size.height * 0.3189,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
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
                            )
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
                    )
                    // search Bar
                    ,
                    const SizedBox(
                      height: 12,
                    ),
                    GenericTextField(
                      textEditingController: _searchController,
                      hint: 'Find your doctor.',
                      radius: 20,
                      alpha: 150,
                      iconButton: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    // Filtters
                    Row(
                      children: [
                        TextButton.icon(
                            onPressed: _show_modal,
                            icon: Icon(Icons.filter_alt_outlined,
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: Text(
                              'Sort by',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                            )),
                      ],
                    )
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
                  DoctorCard(),
                ],
              ),
            ))
          ],
        )));
  }
}
