import 'package:final_project/pages/homepages/models/rive_asset.dart';
import 'package:final_project/pages/homepages/sidebar/info_card.dart';
import 'package:final_project/pages/homepages/sidebar/rive_utils.dart';
import 'package:final_project/pages/homepages/sidebar/side_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  RiveAsset selectedMenu = sideMenus.first;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: 288,
      height: double.infinity,
      color: Colors.black,
      child: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoCard("assets/images/17.jpg",
              name: "Naira Shaban", role: "Admin"),
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 32, bottom: 16),
            child: Text(
              "BROWSE",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
          ),
          ...sideMenus.map((menu) => SideMenuTile(
              menu: menu,
              press: () {
                menu.input!.change(true);
                Future.delayed(const Duration(seconds: 1), () {
                  menu.input!.change(false);
                });
                setState(() {
                  selectedMenu = menu;
                });
              },
              riveonInit: (artboard) {
                StateMachineController controller = RiveUtils.getRiveController(
                    artboard,
                    stateMachineName: menu.stateMachineName);
                menu.input = controller.findSMI('active') as SMIBool;
              },
              isActive: selectedMenu == menu)),
          const Padding(
            padding: EdgeInsets.only(left: 24, top: 32, bottom: 16),
            child: Text(
              "HISTORY",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
          ),
          ...sideMenu2.map((menu) => SideMenuTile(
              menu: menu,
              press: () {
                menu.input!.change(true);
                Future.delayed(const Duration(seconds: 1), () {
                  menu.input!.change(false);
                });
                setState(() {
                  selectedMenu = menu;
                });
              },
              riveonInit: (artboard) {
                StateMachineController controller = RiveUtils.getRiveController(
                    artboard,
                    stateMachineName: menu.stateMachineName);
                menu.input = controller.findSMI('active') as SMIBool;
              },
              isActive: selectedMenu == menu)),
        ],
      )),
    ));
  }
}
