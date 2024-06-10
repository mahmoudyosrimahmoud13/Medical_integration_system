import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 15000),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RotationTransition(
              turns: Tween(begin: 0.0, end: 10000.0).animate(_controller),
              child: SizedBox(
                  height: 100,
                  width: 100,
                  child: SvgPicture(
                      SvgAssetLoader('assets/logo/colored logo.svg'))),
            ),
          ],
        ),
      ),
    );
  }
}
