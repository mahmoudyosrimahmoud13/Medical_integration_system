import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The address of the HealthHub server, chosen in the app and saved on the phone.
///
/// There is no fixed hosting: the server runs on someone's computer and is reached through a
/// Cloudflare link (https://xxxx.trycloudflare.com) or a Wi-Fi address (http://192.168.1.10:8020).
/// So the app asks for the address the first time it opens, and it can be changed any time
/// from the login screen or the profile page.
class ServerSettings {
  ServerSettings._();

  static const _key = 'server_url';

  /// The saved address, like "https://abc.trycloudflare.com" (no /api/v1). Null until one is chosen.
  static final url = ValueNotifier<String?>(null);
  static SharedPreferences? _prefs;

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_key);
    url.value = (saved == null || saved.isEmpty) ? null : saved;
  }

  static Future<void> save(String address) async {
    final clean = normalize(address);
    url.value = clean;
    await _prefs?.setString(_key, clean);
  }

  /// Turns what people paste into a clean base address:
  ///   "abc.trycloudflare.com/"            -> "https://abc.trycloudflare.com"
  ///   "192.168.1.10:8020"                 -> "http://192.168.1.10:8020"
  ///   "https://abc.trycloudflare.com/docs" -> "https://abc.trycloudflare.com"
  static String normalize(String input) {
    var s = input.trim().replaceAll(' ', '');
    if (s.isEmpty) return s;
    if (!s.contains('://')) {
      // Addresses on the same Wi-Fi or computer are plain http; links on the internet are https.
      final local = RegExp(r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(s);
      s = '${local ? 'http' : 'https'}://$s';
    }
    s = s.replaceAll(RegExp(r'/+$'), '');
    for (final tail in const ['/api/v1', '/docs', '/health']) {
      if (s.toLowerCase().endsWith(tail)) s = s.substring(0, s.length - tail.length);
    }
    return s.replaceAll(RegExp(r'/+$'), '');
  }

  /// True when the text looks like a usable web address.
  static bool looksValid(String input) {
    final uri = Uri.tryParse(normalize(input));
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  /// Asks the server's health page. True only if a HealthHub server answers.
  /// /api/v1/health goes through the website port and the Cloudflare link too (they forward /api only).
  static Future<bool> check(String address, {Dio? dio}) async {
    final client = dio ??
        Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
    try {
      final response = await client.get<dynamic>('${normalize(address)}/api/v1/health');
      final data = response.data;
      return response.statusCode == 200 && data is Map && data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Short form for screens: "abc.trycloudflare.com" or "192.168.1.10:8020".
  static String shortName(String? address) {
    if (address == null || address.isEmpty) return '';
    final uri = Uri.tryParse(address);
    if (uri == null || uri.host.isEmpty) return address;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
}
