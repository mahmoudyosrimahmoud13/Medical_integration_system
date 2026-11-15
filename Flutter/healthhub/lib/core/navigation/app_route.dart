import 'package:flutter/material.dart';

/// Page transition used across the app: the new page fades in while sliding up a little.
Route<T> appRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

extension NavigatorX on BuildContext {
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(appRoute(page));

  Future<T?> replaceAll<T>(Widget page) =>
      Navigator.of(this).pushAndRemoveUntil<T>(appRoute(page), (_) => false);

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);
}
