import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'features/auth/presentation/session_cubit.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/home/presentation/home_shell.dart';

/// Lets the network layer reach the session after the app is built.
class UnauthorizedHook {
  VoidCallback? _handler;
  void attach(VoidCallback handler) => _handler = handler;
  void call() => _handler?.call();
}

class HealthHubApp extends StatelessWidget {
  const HealthHubApp({super.key, required this.deps, this.unauthorizedHook});

  final Deps deps;
  final UnauthorizedHook? unauthorizedHook;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Deps>.value(
      value: deps,
      child: BlocProvider(
        create: (_) {
          final session = SessionCubit(deps.auth, deps.tokens)..restore();
          unauthorizedHook?.attach(() {
            if (session.state.status == SessionStatus.loggedIn) session.logout();
          });
          return session;
        },
        child: MaterialApp(
          title: 'HealthHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const AppGate(),
        ),
      ),
    );
  }
}

/// Picks the first screen from the session: splash while checking, onboarding the first time,
/// login when logged out, and the home shell when logged in. Changes cross-fade.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionCubit, SessionState>(
      // Logging out (or an expired token) closes any open pages first.
      listenWhen: (a, b) => a.status != b.status && b.status == SessionStatus.loggedOut,
      listener: (context, _) => Navigator.of(context).popUntil((r) => r.isFirst),
      buildWhen: (a, b) => a.status != b.status || a.onboarded != b.onboarded,
      builder: (context, state) {
        final Widget page = switch (state.status) {
          SessionStatus.unknown => const SplashPage(key: ValueKey('splash')),
          SessionStatus.loggedOut =>
            state.onboarded ? const LoginPage(key: ValueKey('login')) : const OnboardingPage(key: ValueKey('onboarding')),
          SessionStatus.loggedIn => const HomeShell(key: ValueKey('home')),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: .98, end: 1.0).animate(a), child: child),
          ),
          child: page,
        );
      },
    );
  }
}
