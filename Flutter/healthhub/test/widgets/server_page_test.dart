import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/app.dart';
import 'package:healthhub/core/server/server_settings.dart';
import 'package:healthhub/core/storage/token_storage.dart';
import 'package:healthhub/features/auth/presentation/login_page.dart';
import 'package:healthhub/features/server/server_page.dart';

import '../fakes.dart';

void main() {
  tearDown(() => ServerSettings.url.value = null);

  testWidgets('the app asks for the server first, then shows the login screen', (tester) async {
    final deps = fakeDeps(tokens: TokenStorage.memory()..setOnboardingDone());
    await tester.pumpWidget(HealthHubApp(deps: deps, askForServer: true));
    await tester.pumpAndSettle();
    expect(find.byType(ServerPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // An empty address is refused before anything is sent.
    await tester.enterText(find.byKey(const Key('server-address')), '');
    await tester.tap(find.byKey(const Key('server-connect')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the server address'), findsOneWidget);

    // Once an address is saved, the app moves on to the login screen.
    await ServerSettings.save('abc.trycloudflare.com');
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.textContaining('abc.trycloudflare.com'), findsOneWidget);
  });
}
