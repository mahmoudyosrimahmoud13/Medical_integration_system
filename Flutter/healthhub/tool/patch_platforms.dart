// Run after `flutter create .` to give the generated platform folders the HealthHub identity:
// app name, bundle id, internet permission, and a navy status bar.
//   dart run tool/patch_platforms.dart
import 'dart:io';

void main() {
  _replace('android/app/src/main/AndroidManifest.xml', [
    (RegExp(r'android:label="[^"]*"'), 'android:label="HealthHub"'),
    (RegExp(r'<application'), '<uses-permission android:name="android.permission.INTERNET"/>\n    <application'),
    // local dev servers are plain http
    (RegExp(r'android:icon="@mipmap/ic_launcher"'), 'android:icon="@mipmap/ic_launcher"\n        android:usesCleartextTraffic="true"'),
  ]);
  _replace('android/app/build.gradle.kts', [(RegExp(r'applicationId = "[^"]*"'), 'applicationId = "com.healthhub.app"')]);
  _replace('android/app/build.gradle', [(RegExp(r'applicationId "[^"]*"'), 'applicationId "com.healthhub.app"')]);
  _raisePluginCompileSdk();
  _replace('ios/Runner/Info.plist', [
    (RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'), '<key>CFBundleDisplayName</key>\n\t<string>HealthHub</string>'),
    (RegExp(r'<key>CFBundleName</key>\s*<string>[^<]*</string>'), '<key>CFBundleName</key>\n\t<string>HealthHub</string>'),
    (RegExp(r'</dict>\s*</plist>\s*$'), '''\t<key>NSAppTransportSecurity</key>
\t<dict><key>NSAllowsLocalNetworking</key><true/></dict>
\t<key>NSPhotoLibraryUsageDescription</key>
\t<string>Pick a profile photo, a certificate or a scan to upload.</string>
</dict>
</plist>
'''),
  ]);
  _replace('web/index.html', [(RegExp(r'<title>[^<]*</title>'), '<title>HealthHub</title>')]);
  _replace('web/manifest.json', [
    (RegExp(r'"name": "[^"]*"'), '"name": "HealthHub"'),
    (RegExp(r'"short_name": "[^"]*"'), '"short_name": "HealthHub"'),
    (RegExp(r'"background_color": "[^"]*"'), '"background_color": "#1B1F3B"'),
    (RegExp(r'"theme_color": "[^"]*"'), '"theme_color": "#1B1F3B"'),
    (RegExp(r'"description": "[^"]*"'), '"description": "Book doctors, keep your medical record, find pharmacies and hospitals."'),
  ]);
  _replace('windows/runner/main.cpp', [(RegExp(r'L"healthhub"'), 'L"HealthHub"')]);
  _replace('linux/my_application.cc', [(RegExp(r'"healthhub"'), '"HealthHub"')]);
  stdout.writeln('Platform folders patched.');
}

// Some plugins (file_picker) still compile against an older Android SDK, while newer Flutter
// libraries need 36. Raise every Android subproject below 36 to 36 before it builds.
const _compileSdkFix = r'''
// HealthHub: raise plugins that compile against an old Android SDK to 36 (added by tool/patch_platforms.dart)
subprojects {
    val raise: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            val get = android.javaClass.methods.firstOrNull { it.name == "getCompileSdk" && it.parameterCount == 0 }
            val set = android.javaClass.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
            val current = (get?.invoke(android) as? Int) ?: 0
            if (current in 1..35) set?.invoke(android, 36)
        }
    }
    if (state.executed) raise() else afterEvaluate { raise() }
}

''';

void _raisePluginCompileSdk() {
  final file = File('android/build.gradle.kts');
  if (!file.existsSync()) return;
  var text = file.readAsStringSync();
  if (text.contains('HealthHub: raise plugins')) return;
  final at = text.indexOf('subprojects {');
  text = at < 0 ? text + _compileSdkFix : text.substring(0, at) + _compileSdkFix + text.substring(at);
  file.writeAsStringSync(text);
}

void _replace(String path, List<(RegExp, String)> edits) {
  final file = File(path);
  if (!file.existsSync()) return;
  var text = file.readAsStringSync();
  for (final (pattern, replacement) in edits) {
    if (pattern.hasMatch(text)) text = text.replaceFirst(pattern, replacement);
  }
  file.writeAsStringSync(text);
}
