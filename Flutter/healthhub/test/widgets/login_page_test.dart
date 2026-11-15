import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/di.dart';
import 'package:healthhub/core/storage/token_storage.dart';
import 'package:healthhub/app.dart';
import 'package:healthhub/features/auth/presentation/login_page.dart';
import 'package:healthhub/features/auth/presentation/session_cubit.dart';
import 'package:healthhub/features/home/presentation/home_shell.dart';

import '../fakes.dart';

void main() {
  Widget app(Deps deps) => HealthHubApp(deps: deps);

  testWidgets('wrong password shows the server message, right password opens the home shell', (tester) async {
    final deps = fakeDeps(tokens: TokenStorage.memory()..setOnboardingDone());
    await tester.pumpWidget(app(deps));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'sara@test.local');
    await tester.enterText(find.byKey(const Key('login-password')), 'bad');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email Or Password Incorrect'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    await tester.enterText(find.byKey(const Key('login-password')), 'ok');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget); // greeting uses the first name
  });

  testWidgets('empty form shows validation messages and does not call the server', (tester) async {
    final deps = fakeDeps(tokens: TokenStorage.memory()..setOnboardingDone());
    await tester.pumpWidget(app(deps));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email or username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect((deps.auth as FakeAuthRepository).loginCalls, 0);
  });

  testWidgets('a saved session skips login', (tester) async {
    final deps = fakeDeps(tokens: TokenStorage.memory('token')..setOnboardingDone(), sessionSaved: true);
    await tester.pumpWidget(app(deps));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    final session = tester.element(find.byType(HomeShell)).read<SessionCubit>();
    expect(session.state.user?.email, 'sara@test.local');
  });
}
