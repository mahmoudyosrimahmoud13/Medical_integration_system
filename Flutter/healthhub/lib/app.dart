import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'features/auth/presentation/session_cubit.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/home/presentation/home_shell.dart';
import 'core/i18n/i18n.dart';
import 'core/server/server_settings.dart';
import 'features/server/server_page.dart';

/// Lets the network layer reach the session after the app is built.
class UnauthorizedHook {
  VoidCallback? _handler;
  void attach(VoidCallback handler) => _handler = handler;
  void call() => _handler?.call();
}

class HealthHubApp extends StatelessWidget {
  const HealthHubApp({super.key, required this.deps, this.unauthorizedHook, this.askForServer = false});

  final Deps deps;
  final UnauthorizedHook? unauthorizedHook;

  /// Show the server screen first until a server address is saved (the real app does; tests don't).
  final bool askForServer;

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
        // Language and theme come from AppSettings. A language change rebuilds the app from the top
        // (the login stays), so every tr() call picks up the new language and the layout flips to
        // right to left for Arabic.
        child: ValueListenableBuilder<String>(
          valueListenable: AppSettings.lang,
          builder: (context, lang, _) => ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeMode,
            builder: (context, mode, _) => MaterialApp(
              key: ValueKey(lang),
              title: tr('HealthHub'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              locale: Locale(lang),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: askForServer
                  ? ValueListenableBuilder<String?>(
                      valueListenable: ServerSettings.url,
                      builder: (context, url, _) => url == null ? const ServerPage(firstRun: true) : const AppGate(),
                    )
                  : const AppGate(),
            ),
          ),
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
