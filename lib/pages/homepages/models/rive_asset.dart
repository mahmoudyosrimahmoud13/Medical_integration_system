import 'package:rive/rive.dart';

class RiveAsset {
  final String artboard, stateMachineName, title, src;
  late SMIBool? input;

  RiveAsset(this.src,
      {required this.artboard,
      required this.stateMachineName,
      required this.title,
      this.input});
  set setInput(SMIBool status) {
    input = status;
  }
}

List<RiveAsset> sideMenus = [
 RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "HOME",
      stateMachineName: "HOME_interactivity",
      title: "Home"),
  RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "USER",
      stateMachineName: "USER_Interactivity",
      title: "Profile"),
  RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "SEARCH",
      stateMachineName: "SEARCH_Interactivity",
      title: "Search"),
  RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "CHAT", stateMachineName: "CHAT_Interactivity", title: "Chat"),
];
List<RiveAsset> sideMenu2 = [
  RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "TIMER", stateMachineName: "TIMER_Interactivity", title: "History"),
  RiveAsset("assets/rivimg/animated_icon_set_-_1_color.riv",
      artboard: "BELL", stateMachineName: "BELL_Interactivity", title: "Notifications")
];
