import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

/// Returns false immediately on web — biometrics are not supported.
Future<bool> isBiometricAvailable() async {
  if (kIsWeb) return false;
  try {
    if (!await _auth.canCheckBiometrics) return false;
    final list = await _auth.getAvailableBiometrics();
    return list.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// On web, returns true immediately (no-op passthrough).
/// On mobile, calls local_auth with biometricOnly + stickyAuth.
Future<bool> authenticate({required String reason}) async {
  if (kIsWeb) return true;
  try {
    return await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  } catch (_) {
    return false;
  }
}

/// Writes biometricEnabled flag to /users/{uid}.
Future<void> setBiometricEnabled(String uid, bool enabled) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'biometricEnabled': enabled,
    'biometricEnabledAt': FieldValue.serverTimestamp(),
  });
}

/// Reads biometricEnabled from /users/{uid}.
Future<bool> isBiometricEnabledForUser(String uid) async {
  if (kIsWeb) return false;
  try {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['biometricEnabled'] as bool?) ?? false;
  } catch (_) {
    return false;
  }
}
