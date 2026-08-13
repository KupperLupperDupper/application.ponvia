import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/data/security/app_lock_store.dart';

void main() {
  final salt = base64Encode(List<int>.generate(16, (i) => i));
  final salt2 = base64Encode(List<int>.generate(16, (i) => 255 - i));

  test('pinHash is deterministic for the same pin + salt', () {
    expect(pinHash('1234', salt), pinHash('1234', salt));
  });

  test('a different PIN yields a different hash', () {
    expect(pinHash('1234', salt), isNot(pinHash('1235', salt)));
  });

  test('the same PIN under a different salt yields a different hash', () {
    expect(pinHash('1234', salt), isNot(pinHash('1234', salt2)));
  });

  test('the hash never contains the plaintext PIN', () {
    expect(pinHash('1234', salt).contains('1234'), isFalse);
  });
}
