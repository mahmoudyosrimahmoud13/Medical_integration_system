import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the login token in memory (for fast, synchronous reads on every request)
/// and on disk (so the user stays logged in after closing the app).
class TokenStorage {
  TokenStorage(this._prefs) : _token = _prefs?.getString(_key);

  /// In-memory only. Used by tests.
  TokenStorage.memory([String? token])
      : _prefs = null,
        _token = token;

  static const _key = 'auth_token';
  static const _onboardingKey = 'onboarding_done';
  static const _modeKey = 'workspace_mode';

  final SharedPreferences? _prefs;
  String? _token;
  bool _onboardingDone = false;

  static Future<TokenStorage> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs).._onboardingDone = prefs.getBool(_onboardingKey) ?? false;
  }

  String? get token => _token;

  Future<void> save(String token) async {
    _token = token;
    await _prefs?.setString(_key, token);
  }

  Future<void> clear() async {
    _token = null;
    await _prefs?.remove(_key);
    await _prefs?.remove(_modeKey);
  }

  bool get onboardingDone => _onboardingDone;

  Future<void> setOnboardingDone() async {
    _onboardingDone = true;
    await _prefs?.setBool(_onboardingKey, true);
  }

  String? get workspace => _prefs?.getString(_modeKey);

  Future<void> saveWorkspace(String mode) async => _prefs?.setString(_modeKey, mode);
}
