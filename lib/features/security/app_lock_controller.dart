import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/security/app_lock_store.dart';

/// Whether this device can do fingerprint auth (supported + at least one
/// enrolment). Drives the "No fingerprints on this phone" disabled state.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.isDeviceSupported()) return false;
    if (!await auth.canCheckBiometrics) return false;
    return (await auth.getAvailableBiometrics()).isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// App-lock state. [enabled] = a PIN is set; [unlocked] = this session has been
/// unlocked (reset on resume so the lock re-applies). [biometricEnabled] adds a
/// fingerprint shortcut on top of the always-present PIN.
@immutable
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.biometricEnabled,
    required this.unlocked,
  });

  final bool enabled;
  final bool biometricEnabled;
  final bool unlocked;

  /// Whether the lock screen should currently be shown.
  bool get isLocked => enabled && !unlocked;

  AppLockState copyWith({bool? enabled, bool? biometricEnabled, bool? unlocked}) =>
      AppLockState(
        enabled: enabled ?? this.enabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        unlocked: unlocked ?? this.unlocked,
      );
}

/// Overridden in `main` with the store instance.
final appLockStoreProvider = Provider<AppLockStore>((ref) => AppLockStore());

/// Overridden in `main` with the state loaded during bootstrap, so the router
/// can gate the very first frame without a flash of the home screen.
final initialAppLockStateProvider = Provider<AppLockState>(
  (ref) => const AppLockState(
      enabled: false, biometricEnabled: false, unlocked: true),
);

class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() => ref.read(initialAppLockStateProvider);

  AppLockStore get _store => ref.read(appLockStoreProvider);

  /// Marks the current session unlocked (correct PIN or accepted fingerprint).
  void markUnlocked() => state = state.copyWith(unlocked: true);

  /// Re-arms the lock (called when the app is backgrounded), so returning to it
  /// shows the lock screen again — there is no timer.
  void relock() {
    if (state.enabled) state = state.copyWith(unlocked: false);
  }

  Future<bool> verify(String pin) => _store.verifyPin(pin);

  /// Turns the lock on with a freshly chosen PIN.
  Future<void> enable(String pin) async {
    await _store.setPin(pin);
    await setWindowSecure(true);
    state = state.copyWith(enabled: true, unlocked: true);
  }

  /// Turns the lock off (requires the caller to have verified the current PIN).
  Future<void> disable() async {
    await _store.clear();
    await setWindowSecure(false);
    state =
        state.copyWith(enabled: false, biometricEnabled: false, unlocked: true);
  }

  Future<void> changePin(String pin) => _store.setPin(pin);

  Future<void> setBiometric(bool on) async {
    await _store.setBiometricEnabled(on);
    state = state.copyWith(biometricEnabled: on);
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
