import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.currentIndex, required this.ontap});

  final int currentIndex;
  final Function(int value) ontap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AnimatedBottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        icons: const [
          Icons.reorder_rounded,
          Icons.schedule,
          Icons.search,
          Icons.description
        ],
        activeIndex: currentIndex,
        onTap: ontap,
        elevation: 20,
        gapLocation: GapLocation.center,
        activeColor: Theme.of(context).colorScheme.primary,
        blurEffect: true,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
      ),
    );
  }
}
