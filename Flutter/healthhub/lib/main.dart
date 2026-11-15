import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/di.dart';
import 'core/i18n/i18n.dart';
import 'core/network/api_client.dart';
import 'core/server/server_settings.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load(); // language and theme saved on the phone
  await ServerSettings.load(); // the server address chosen in the app, if any
  final tokens = await TokenStorage.load();

  // The session cubit is created inside the app; this hook lets the network layer
  // log the user out when the server says the token is no longer valid.
  final unauthorized = UnauthorizedHook();
  final api = DioApiClient(baseUrl: AppConfig.apiV1, tokens: tokens, onUnauthorized: unauthorized.call);
  // When the server address changes in the app, every following request goes to the new one.
  ServerSettings.url.addListener(() => api.baseUrl = AppConfig.apiV1);

  runApp(HealthHubApp(deps: Deps.fromApi(api, tokens), unauthorizedHook: unauthorized, askForServer: true));
}
