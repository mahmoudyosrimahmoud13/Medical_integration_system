import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:final_project/pages/home/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AnimatedSplashScreenPage extends StatelessWidget {
  const AnimatedSplashScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splashIconSize: 400,
      pageTransitionType: PageTransitionType.leftToRight,
      splash: Container(
        height: 1000,
        width: 700,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/1.gif'), fit: BoxFit.fill)),
      ),
      nextScreen: const OnBoardingPage(),
      animationDuration: const Duration(seconds: 3),
    );
  }
}
