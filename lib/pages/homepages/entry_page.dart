import 'dart:math';

import 'package:final_project/pages/homepages/models/menu_btn.dart';
import 'package:final_project/pages/homepages/sidebar/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'package:final_project/pages/homepages/homee.dart';
import 'package:final_project/pages/homepages/sidebar/rive_utils.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animatedController;
  late Animation<double> animation;
  late SMIBool isSideBarClosed;
  bool isSideMenuClosed = true;
  @override
  void initstate() {
    _animatedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });
    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animatedController, curve: Curves.fastOutSlowIn));
    super.initState();
  }

  @override
  void dispose() {
    _animatedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              width: 288,
              left: isSideMenuClosed ? -288 : 0,
              height: MediaQuery.of(context).size.height,
              child: const Sidebar()),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(1 - 30 * pi / 180),
            child: Transform.translate(
              offset: Offset(isSideMenuClosed ? 0 : 288, 0),
              child: Transform.scale(
                  scale: isSideMenuClosed ? 1 : 0.8,
                  child: const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      child: Homee())),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideMenuClosed ? 0 : 220,
            top: 16,
            child: menuBtn(
              riveOnInit: (artboard) {
                StateMachineController controller = RiveUtils.getRiveController(
                    artboard,
                    stateMachineName: "State Machine");
                isSideBarClosed = controller.findSMI("isOpen") as SMIBool;
                isSideBarClosed.value = true;
              },
              press: () {
                isSideBarClosed.value = !isSideBarClosed.value;
                setState(() {
                  isSideMenuClosed = isSideBarClosed.value;
                });
              },
            ),
          )
        ]));
  }
}
