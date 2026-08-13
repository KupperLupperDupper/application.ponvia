import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the app-lock secret. The PIN is Ponvia's own and is stored **only**
/// as a salted, stretched hash in platform secure storage — never in plaintext,
/// never synced, with no recovery path (a forgotten PIN means clearing data).
class AppLockStore {
  AppLockStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kHash = 'applock.pinHash';
  static const _kSalt = 'applock.pinSalt';
  static const _kBiometric = 'applock.biometric';

  /// Whether a PIN (i.e. the app lock) has been set.
  Future<bool> hasPin() async => (await _storage.read(key: _kHash)) != null;

  Future<void> setPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltB64 = base64Encode(salt);
    await _storage.write(key: _kSalt, value: saltB64);
    await _storage.write(key: _kHash, value: pinHash(pin, saltB64));
  }

  Future<bool> verifyPin(String pin) async {
    final saltB64 = await _storage.read(key: _kSalt);
    final expected = await _storage.read(key: _kHash);
    if (saltB64 == null || expected == null) return false;
    return pinHash(pin, saltB64) == expected;
  }

  /// Clears the PIN and biometric flag (disable lock, or "forgot PIN" reset).
  Future<void> clear() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kBiometric);
  }

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometric)) == 'true';

  Future<void> setBiometricEnabled(bool on) =>
      _storage.write(key: _kBiometric, value: on ? 'true' : 'false');
}

/// Stretch iterations — cheap enough for an instant unlock, enough to slow a
/// brute-force of the hash if secure storage were ever exfiltrated.
const _pinIterations = 20000;

/// Salted, stretched hash of a PIN (base64 salt in, base64 hash out). Top-level
/// and deterministic so it can be unit-tested without touching secure storage.
String pinHash(String pin, String saltB64) {
  final salt = base64Decode(saltB64);
  var bytes = sha256.convert([...utf8.encode(pin), ...salt]).bytes;
  for (var i = 0; i < _pinIterations; i++) {
    bytes = sha256.convert([...bytes, ...salt]).bytes;
  }
  return base64Encode(bytes);
}

/// Toggles the native window's FLAG_SECURE (hides content from the task switcher
/// and blocks screenshots) while the lock is enabled. No-op off Android.
const _secureChannel = MethodChannel('ponvia/secure_window');

Future<void> setWindowSecure(bool on) async {
  try {
    await _secureChannel.invokeMethod<void>('setSecure', on);
  } on MissingPluginException {
    // Non-Android platform without the channel — ignore.
  }
}
