import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:healthhub/widgets/doctor_card.dart';
import 'package:intl/intl.dart';

import 'package:healthhub/widgets/generic_texfield.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final TextEditingController _searchController = TextEditingController();
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
                          onPressed: () {},
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
              flex: 5,
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
      )),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: CircleBorder(),
        elevation: 5,
        clipBehavior: Clip.hardEdge,
        onPressed: () {},
        child: Icon(
          Icons.bookmark_add_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: AnimatedBottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          icons: [
            Icons.reorder_rounded,
            Icons.person_2_rounded,
            Icons.search,
            Icons.home_rounded
          ],
          activeIndex: _currentIndex,
          onTap: (value) {
            setState(() {
              _currentIndex = value;
            });
          },
          elevation: 20,
          gapLocation: GapLocation.center,
          activeColor: Theme.of(context).colorScheme.primary,
          blurEffect: true,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
        ),
      ),
    );
  }
}
