import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Staggered entrance for list items: each item fades and slides in a little after the one before.
extension EntranceX on Widget {
  Widget entrance(int index, {double dy = .12, int baseDelayMs = 40, int maxDelayMs = 400}) {
    final delay = math.min(index * baseDelayMs, maxDelayMs);
    return animate(delay: delay.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: dy, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }

  /// A soft "pop" used for success marks and badges.
  Widget popIn({int delayMs = 0}) => animate(delay: delayMs.ms)
      .scaleXY(begin: .6, end: 1, duration: 500.ms, curve: Curves.elasticOut)
      .fadeIn(duration: 200.ms);
}

/// Shrinks slightly while pressed, then springs back.
/// It only listens to the finger, so it works around any InkWell or button.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = .97});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    );
    if (widget.onTap != null) child = GestureDetector(onTap: widget.onTap, child: child);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: child,
    );
  }
}

/// Grey placeholder blocks with a light sweep, shown while data loads.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final light = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: [base, light, base],
          stops: const [.1, .5, .9],
          begin: Alignment(-1 - 2 * (1 - _c.value), 0),
          end: Alignment(1 + 2 * _c.value, 0),
        ).createShader(rect),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// A list of card-shaped placeholders.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5, this.itemHeight = 86});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Row(children: [
          SkeletonBox(height: itemHeight - 30, width: itemHeight - 30, radius: 16),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(height: 16, width: 160),
              SizedBox(height: 10),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(height: 12, width: 100),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The HealthHub mark (three stems, one shared bar). [white] is for dark or coloured backgrounds.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.white = false});

  final double size;
  final bool white;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        white ? 'assets/logo/logo_mark_white.svg' : 'assets/logo/logo_mark.svg',
        width: size,
        height: size,
        semanticsLabel: 'HealthHub',
      );
}

/// Logo + "HealthHub" text, side by side.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : const Color(0xFF1B1F3B);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AppLogo(size: size, white: onDark),
      SizedBox(width: size * .28),
      Text('HealthHub', style: TextStyle(color: color, fontSize: size * .62, fontWeight: FontWeight.w800, letterSpacing: -1)),
    ]);
  }
}

/// The logo, gently pulsing like a heartbeat. Used on the splash screen.
class PulsingLogo extends StatefulWidget {
  const PulsingLogo({super.key, this.size = 110});

  final double size;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo> with SingleTickerProviderStateMixin {
  // Three heartbeats, then rest. A finite animation also lets widget tests settle.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  int _beats = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _c.reverse();
      } else if (status == AnimationStatus.dismissed && ++_beats < 3) {
        _c.forward();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: .94, end: 1.06).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * .25),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: SvgPicture.asset('assets/logo/logo.svg', width: widget.size, height: widget.size),
      ),
    );
  }
}
