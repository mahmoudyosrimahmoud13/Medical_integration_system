import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/i18n/i18n.dart';

void main() {
  tearDown(() => AppSettings.lang.value = 'en');

  test('English shows the key, with placeholders filled', () {
    expect(tr('Book with Dr. {name}', {'name': 'Sara'}), 'Book with Dr. Sara');
  });

  test('Arabic uses the dictionary and falls back to English', () {
    AppSettings.lang.value = 'ar';
    expect(tr('Book with Dr. {name}', {'name': 'Sara'}), 'احجز مع د. Sara');
    expect(tr('Something not translated'), 'Something not translated');
    expect(clock('01:00 PM'), '01:00 م');
  });

  test('Place names switch with the language', () {
    expect(place('Cairo', 'القاهرة'), 'Cairo');
    AppSettings.lang.value = 'ar';
    expect(place('Cairo'), 'القاهرة');
  });
}
