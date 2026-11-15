import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ar.dart';

/// English and Arabic, plus light / dark / system theme. Both are saved on the phone.
///
/// The English text is the key: tr('Book a doctor') gives the Arabic when Arabic is on and the
/// English otherwise (also when a translation is missing). {name} placeholders are filled from vars.
/// Changing the language rebuilds the whole app (see app.dart), so plain tr() calls are enough.
class AppSettings {
  AppSettings._();

  static const _langKey = 'lang';
  static const _themeKey = 'theme';

  static final lang = ValueNotifier<String>('en');
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static SharedPreferences? _prefs;

  static bool get isArabic => lang.value == 'ar';
  static Locale get locale => Locale(lang.value);
  /// Locale for DateFormat. English uses the built-in default, so nothing needs loading for it.
  static String? get dateLocale => isArabic ? 'ar' : null;

  /// Reads the saved choices. The first time, the phone's language decides.
  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    lang.value = _prefs!.getString(_langKey) ?? (device == 'ar' ? 'ar' : 'en');
    themeMode.value = switch (_prefs!.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    await initializeDateFormatting('ar');
  }

  static Future<void> setLang(String value) async {
    lang.value = value;
    await _prefs?.setString(_langKey, value);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs?.setString(_themeKey, mode.name);
  }
}

String _fill(String text, Map<String, Object?>? vars) {
  if (vars == null) return text;
  return text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${vars[m.group(1)] ?? m.group(0)}');
}

/// Translate a piece of interface text.
String tr(String text, [Map<String, Object?>? vars]) => _fill(AppSettings.isArabic ? (ar[text] ?? text) : text, vars);

final _placeNames = <String, String>{};

/// A governorate or area name in the current language. The database stores the Arabic name;
/// some answers only carry the English name, so Arabic names already seen are remembered.
String place(String? key, [String? nameAr]) {
  if (key == null || key.isEmpty) return '';
  if (nameAr != null && nameAr.isNotEmpty) _placeNames[key] = nameAr;
  return AppSettings.isArabic ? (nameAr ?? _placeNames[key] ?? key) : key;
}

/// Server clock times ("01:00 PM") with ص / م in Arabic. Only for showing.
String clock(String? t) {
  if (t == null) return '';
  return AppSettings.isArabic ? t.replaceAll('AM', 'ص').replaceAll('PM', 'م') : t;
}

/// Reads a place from the API ({key, name_ar}), remembers its Arabic name, and returns the English
/// key to store in models. Screens then show it with place(key).
String rememberPlace(Object? json) {
  final m = json is Map ? json : const {};
  final key = '${m['key'] ?? ''}';
  final ar = m['name_ar'];
  if (ar is String && ar.isNotEmpty) _placeNames[key] = ar;
  return key;
}
