import 'package:final_project/logics/cache_helper.dart';
import 'package:final_project/logics/helper_methods.dart';
import 'package:final_project/pages/SignUp/home_page.dart';
import 'package:final_project/pages/animated%20screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
await  CacheHelper.init();
 
  final onboarding = CacheHelper.getOnBoarding() ?? false;
  runApp(MyApp(onboarding: onboarding));
}

class MyApp extends StatelessWidget {
  final bool onboarding;
  const MyApp({super.key, this.onboarding = false});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Medical App',
        home: onboarding ? const Home() : const AnimatedSplashScreenPage());
  }
}
