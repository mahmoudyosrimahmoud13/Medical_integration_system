import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/di.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = await TokenStorage.load();

  // The session cubit is created inside the app; this hook lets the network layer
  // log the user out when the server says the token is no longer valid.
  final unauthorized = UnauthorizedHook();
  final api = DioApiClient(baseUrl: AppConfig.apiV1, tokens: tokens, onUnauthorized: unauthorized.call);

  runApp(HealthHubApp(deps: Deps.fromApi(api, tokens), unauthorizedHook: unauthorized));
}
