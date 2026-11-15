import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/animations.dart';
import 'session_cubit.dart';

class _Slide {
  const _Slide(this.image, this.title, this.text);
  final String image;
  final String title;
  final String text;
}

const _slides = [
  _Slide('assets/images/onboarding_doctors.svg', 'Find the right doctor',
      'Search by specialty and area, compare ratings and prices, and see when each doctor works.'),
  _Slide('assets/images/onboarding_booking.svg', 'Book in seconds',
      'Pick a free hour, get reminders, and move or cancel your visit any time.'),
  _Slide('assets/images/onboarding_records.svg', 'Your record, always with you',
      'Prescriptions, diagnoses and scans in one place. Share them with a pharmacy using a one-time code.'),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<SessionCubit>().finishOnboarding();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              const AppWordmark(size: 32),
              const Spacer(),
              TextButton(onPressed: _finish, child: const Text('Skip')),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Expanded(
                      child: SvgPicture.asset(s.image)
                          .animate(key: ValueKey('img$i'))
                          .fadeIn(duration: 500.ms)
                          .scaleXY(begin: .85, end: 1, duration: 600.ms, curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: 24),
                    Text(s.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))
                        .animate(key: ValueKey('t$i'))
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: .3, end: 0),
                    const SizedBox(height: 12),
                    Text(s.text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5))
                        .animate(key: ValueKey('b$i'))
                        .fadeIn(delay: 300.ms),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: i == _page ? 28 : 8,
                decoration: BoxDecoration(
                  color: i == _page ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: last
                  ? _finish
                  : () => _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(last ? 'Get started' : 'Next', key: ValueKey(last)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
