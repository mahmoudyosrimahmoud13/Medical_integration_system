import 'package:flutter/material.dart';
import 'package:healthhub/screens/home/search_screen.dart';
import 'package:healthhub/widgets/nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SearchScreen(),
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
        bottomNavigationBar: NavBar(
          currentIndex: _currentIndex,
          ontap: (value) {
            setState(() {
              _currentIndex = value;
            });
          },
        ));
  }
}
