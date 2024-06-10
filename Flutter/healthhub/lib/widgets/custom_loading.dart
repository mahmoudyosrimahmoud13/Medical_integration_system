import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomLoading extends StatefulWidget {
  const CustomLoading({super.key});

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading>
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RotationTransition(
            turns: Tween(begin: 0.0, end: 10000.0).animate(_controller),
            child: const SizedBox(
                height: 100,
                width: 100,
                child:
                    SvgPicture(SvgAssetLoader('assets/logo/colored logo.svg'))),
          ),
        ],
      ),
    );
  }
}
