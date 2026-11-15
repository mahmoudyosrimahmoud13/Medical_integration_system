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

void _replace(String path, List<(RegExp, String)> edits) {
  final file = File(path);
  if (!file.existsSync()) return;
  var text = file.readAsStringSync();
  for (final (pattern, replacement) in edits) {
    if (pattern.hasMatch(text)) text = text.replaceFirst(pattern, replacement);
  }
  file.writeAsStringSync(text);
}
