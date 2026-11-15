import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/load_cubit.dart';
import '../theme/app_theme.dart';
import 'animations.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    backgroundColor: error ? AppColors.danger : null,
    content: Row(children: [
      Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
  ));
}

/// Main action button. Shows a spinner while [busy] and ignores taps.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
        child: busy
            ? const SizedBox(key: ValueKey('busy'), height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Row(key: const ValueKey('label'), mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ]),
      ),
    );
  }
}

/// Illustration + text, for empty lists and first-time screens.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.message, this.image = 'assets/images/search.svg', this.action});

  final String title;
  final String? message;
  final String image;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(image, height: 170)
              .animate()
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: .9, end: 1, duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 150.ms),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: t.bodyMedium?.copyWith(color: t.bodySmall?.color), textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 250.ms),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!.animate().fadeIn(delay: 350.ms)],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      image: 'assets/images/no_results.svg',
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
    );
  }
}

/// Renders a [LoadState]: skeleton while loading, error with retry, empty view, or the data.
/// Switching between them cross-fades.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.loading,
  });

  final LoadState<T> state;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    final data = state.data;
    if (data != null) {
      child = (isEmpty?.call(data) ?? false) && empty != null
          ? KeyedSubtree(key: const ValueKey('empty'), child: empty!)
          : KeyedSubtree(key: const ValueKey('data'), child: builder(data));
    } else if (state.status == LoadStatus.failure) {
      child = KeyedSubtree(key: const ValueKey('error'), child: ErrorView(message: state.error ?? '', onRetry: onRetry));
    } else {
      child = KeyedSubtree(key: const ValueKey('loading'), child: loading ?? const SkeletonList());
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child);
  }
}

/// Circle avatar from a URL with initials as a fallback.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.url, this.radius = 26, this.heroTag});

  final String name;
  final String? url;
  final double radius;
  final Object? heroTag;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = url != null && url!.isNotEmpty && !url!.endsWith('/default.png');
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: hasImage ? NetworkImage(url!) : null,
      child: Text(_initials, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: radius * .6)),
    );
    if (heroTag != null) avatar = Hero(tag: heroTag!, child: avatar);
    return avatar;
  }
}

/// A card with padding and an optional tap that scales on press.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
    return onTap == null ? card : Pressable(child: card);
  }
}

/// Coloured header with a curved bottom, used at the top of main tabs.
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, required this.title, this.subtitle, this.trailing, this.bottom, this.gradient});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 14))
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -.1, end: 0),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideX(begin: -.08, end: 0),
            ]),
          ),
          if (trailing != null) trailing!.animate().fadeIn(delay: 150.ms).scaleXY(begin: .8, end: 1),
        ]),
        if (bottom != null) ...[const SizedBox(height: 18), bottom!.animate().fadeIn(delay: 200.ms).slideY(begin: .2, end: 0)],
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          if (action != null) action!,
        ]),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'accepted' => (AppColors.accent, 'Accepted'),
      'rejected' => (AppColors.danger, 'Rejected'),
      'pending' => (AppColors.warning, 'Under review'),
      'cancelled' => (AppColors.danger, 'Cancelled'),
      'booked' => (AppColors.primary, 'Booked'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

/// Small numeric stat with a count-up animation.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color});

  final String label;
  final num value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: c),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            value is int ? v.round().toString() : v.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
