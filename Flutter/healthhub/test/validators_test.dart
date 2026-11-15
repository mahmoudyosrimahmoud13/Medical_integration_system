import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/utils/validators.dart';

void main() {
  test('email', () {
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('nope'), isNotNull);
  });

  test('password follows the server rule', () {
    expect(Validators.password('Strong@123'), isNull);
    expect(Validators.password('short1A@'), isNull);
    expect(Validators.password('weak'), isNotNull);
    expect(Validators.password('alllowercase1@'), isNotNull);
    expect(Validators.password('NoSymbol123'), isNotNull);
  });

  test('egyptian phone', () {
    expect(Validators.phone('01012345678'), isNull);
    expect(Validators.phone('+201512345678'), isNull);
    expect(Validators.phone('0123'), isNotNull);
    expect(Validators.phone('01312345678'), isNotNull);
  });

  test('national id', () {
    expect(Validators.nationalId('29505051234567'), isNull);
    expect(Validators.nationalId('19505051234567'), isNotNull);
    expect(Validators.nationalId('29513051234567'), isNotNull); // month 13
    expect(Validators.nationalId('1234'), isNotNull);
  });

  test('match', () {
    expect(Validators.match(() => 'abc')('abc'), isNull);
    expect(Validators.match(() => 'abc')('abd'), isNotNull);
  });
}
