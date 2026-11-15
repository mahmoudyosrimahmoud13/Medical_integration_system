import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animations.dart';

/// Light claymorphism: soft, puffy, rounded surfaces with a highlight on the top left and a soft
/// shadow on the bottom right, like modelling clay.
///
/// Used only where it helps: the patient home screen, onboarding and empty states.
/// Staff workspaces, records, prescriptions and interaction warnings stay flat on purpose,
/// so medical information always looks clear and serious.
class Clay {
  Clay._();

  // Pastel tints of the brand colours (indigo, mint, amber, red). Text on them stays navy for contrast.
  static const lilac = Color(0xFFE3E6FF);
  static const mint = Color(0xFFD5F6EC);
  static const butter = Color(0xFFFFF0C4);
  static const blush = Color(0xFFFFE0E1);
  static const cloud = Color(0xFFF4F5FB);

  static BoxDecoration decoration(BuildContext context, Color tint, {double radius = 28, bool flat = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final base = dark ? Color.lerp(tint, surface, .82)! : tint;
    final highlight = Color.lerp(base, Colors.white, dark ? .06 : .6)!;
    final shade = Color.lerp(base, AppColors.navy, dark ? .6 : .28)!;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [highlight, base]),
      border: Border.all(color: Colors.white.withValues(alpha: dark ? .06 : .75), width: 1.4),
      boxShadow: flat
          ? null
          : [
              BoxShadow(color: shade.withValues(alpha: dark ? .55 : .32), offset: const Offset(7, 9), blurRadius: 22),
              BoxShadow(color: Colors.white.withValues(alpha: dark ? .03 : .9), offset: const Offset(-5, -5), blurRadius: 14),
            ],
    );
  }
}

/// A puffy rounded card. Pass [onTap] to make it pressable (it squishes a little when pressed).
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.tint = Clay.cloud,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
  });

  final Widget child;
  final Color tint;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(padding: padding, decoration: Clay.decoration(context, tint, radius: radius), child: child);
    return onTap == null ? box : Pressable(onTap: onTap, scale: .95, child: box);
  }
}

/// A round clay blob holding an icon, used on action cards and empty states.
class ClayBubble extends StatelessWidget {
  const ClayBubble({super.key, required this.icon, this.color = AppColors.primary, this.tint = Colors.white, this.size = 54});

  final IconData icon;
  final Color color;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: Clay.decoration(context, tint, radius: size / 2.4),
      child: Icon(icon, color: color, size: size * .5),
    );
  }
}
