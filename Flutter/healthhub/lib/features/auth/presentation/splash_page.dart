import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const PulsingLogo(size: 110).animate().fadeIn(duration: 500.ms).scaleXY(begin: .7, end: 1, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text('HealthHub', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -.5))
                .animate()
                .fadeIn(delay: 250.ms, duration: 500.ms)
                .slideY(begin: .3, end: 0),
            const SizedBox(height: 6),
            const Text('All your care, connected', style: TextStyle(color: Color(0xFFFFC53D), fontSize: 15, fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),
          ]),
        ),
      ),
    );
  }
}
