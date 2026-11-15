import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/server/server_settings.dart';

void main() {
  test('pasted addresses are cleaned up', () {
    expect(ServerSettings.normalize(' abc.trycloudflare.com/ '), 'https://abc.trycloudflare.com');
    expect(ServerSettings.normalize('https://abc.trycloudflare.com/docs'), 'https://abc.trycloudflare.com');
    expect(ServerSettings.normalize('https://abc.trycloudflare.com/api/v1/'), 'https://abc.trycloudflare.com');
    expect(ServerSettings.normalize('192.168.1.10:8020'), 'http://192.168.1.10:8020');
    expect(ServerSettings.normalize('localhost:8020'), 'http://localhost:8020');
    expect(ServerSettings.normalize('http://10.0.2.2:8020/health'), 'http://10.0.2.2:8020');
  });

  test('only web addresses are accepted', () {
    expect(ServerSettings.looksValid('abc.trycloudflare.com'), isTrue);
    expect(ServerSettings.looksValid('http://192.168.1.10:8020'), isTrue);
    expect(ServerSettings.looksValid(''), isFalse);
    expect(ServerSettings.looksValid('ftp://files.example.com'), isFalse);
  });

  test('short names for screens', () {
    expect(ServerSettings.shortName('https://abc.trycloudflare.com'), 'abc.trycloudflare.com');
    expect(ServerSettings.shortName('http://192.168.1.10:8020'), '192.168.1.10:8020');
  });

  test('an address with no server behind it fails the check', () async {
    expect(await ServerSettings.check('http://127.0.0.1:1'), isFalse);
  });
}
