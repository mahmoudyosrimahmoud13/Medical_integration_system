import 'package:flutter/material.dart';
import 'package:healthhub/constants/colors.dart';
import 'package:healthhub/constants/themes.dart';
import 'package:healthhub/screens/onboarding/onboarding.dart';
import 'package:healthhub/screens/splash.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: mainTheme,
      darkTheme: darkTheme,
      home: const OnboardingScreen(),
    );
  }
}
