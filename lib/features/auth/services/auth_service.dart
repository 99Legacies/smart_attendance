import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attendance/core/helpers/biometric_helper.dart';
import 'package:smart_attendance/core/helpers/device_id_helper.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/features/auth/services/session_guard.dart';

sealed class LoginResult {
  const LoginResult();
}

final class LoginSuccess extends LoginResult {
  const LoginSuccess({required this.uid, required this.role});
  final String uid;
  final UserRole role;
}

final class LoginDeviceConflict extends LoginResult {
  const LoginDeviceConflict({required this.existingDeviceId});
  final String existingDeviceId;
}

final class LoginBiometricFailed extends LoginResult {
  const LoginBiometricFailed({required this.uid});
  final String uid;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  static const _kDeviceIdKey = '_sid';
  static const _kSessionTokenKey = '_stk';

  /// Signs in with email + password, asks the backend to bind or refresh the
  /// single-device session, then runs biometric verification if enabled.
  Future<LoginResult> login(String email, String password) async {
    SessionGuard.suspend();
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    final uid = cred.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final role = UserRole.fromString((data['role'] as String?) ?? 'student');
    final deviceId = await getDeviceId();
    var keepGuardSuspendedForConflict = false;

    try {
      developer.log(
        'LOGIN_BIND:start uid=$uid deviceId=$deviceId',
        name: 'AuthService',
      );
      await _bindOrRefreshSession(deviceId);
      developer.log(
        'LOGIN_BIND:success uid=$uid deviceId=$deviceId',
        name: 'AuthService',
      );
    } on _SessionConflict catch (conflict) {
      keepGuardSuspendedForConflict = true;
      developer.log(
        'LOGIN_BIND:conflict uid=$uid existingDeviceId=${conflict.existingDeviceId}',
        name: 'AuthService',
      );
      return LoginDeviceConflict(existingDeviceId: conflict.existingDeviceId);
    } catch (error, stack) {
      developer.log(
        'LOGIN_BIND:failed uid=$uid error=$error',
        name: 'AuthService',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      if (!keepGuardSuspendedForConflict) {
        SessionGuard.resume();
      }
    }

    return _biometricGate(uid, role);
  }

  /// Runs the confirmed session override on the backend and waits for the
  /// Firestore success state that proves the swap committed.
  Future<LoginResult> forceLogin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const LoginDeviceConflict(existingDeviceId: '');
    }

    SessionGuard.suspend();

    final deviceId = await getDeviceId();
    try {
      developer.log(
        'OVERRIDE_SESSION:start uid=$uid newDeviceId=$deviceId',
        name: 'AuthService',
      );
      final swap = await _overrideSession(uid: uid, newDeviceId: deviceId);
      await _persistLocalSession(
        deviceId: swap.deviceId,
        sessionToken: swap.sessionToken,
      );
      await _watchSwapUntilCompleted(uid: uid, swapId: swap.swapId);
      await _auth.currentUser?.getIdToken(true);
      developer.log(
        'OVERRIDE_SESSION:success uid=$uid swapId=${swap.swapId} '
        'newDeviceId=${swap.deviceId} role=${swap.role.name}',
        name: 'AuthService',
      );
      return _biometricGate(uid, swap.role);
    } catch (error, stack) {
      developer.log(
        'OVERRIDE_SESSION:failed uid=$uid error=$error',
        name: 'AuthService',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      SessionGuard.resume();
    }
  }

  Future<void> signOut() async {
    SessionGuard.stop();
    SessionGuard.resume();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeviceIdKey);
    await prefs.remove(_kSessionTokenKey);
    await _auth.signOut();
  }

  Future<LoginResult> _biometricGate(String uid, UserRole role) async {
    final available = await isBiometricAvailable();
    final enabled = await isBiometricEnabledForUser(uid);
    if (available && enabled) {
      final passed = await authenticate(
        reason: 'Confirm your identity to continue',
      );
      if (!passed) return LoginBiometricFailed(uid: uid);
    }
    return LoginSuccess(uid: uid, role: role);
  }

  Future<void> _bindOrRefreshSession(String deviceId) async {
    try {
      final callable = _functions.httpsCallable(
        'bindSession',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call<Map<Object?, Object?>>({
        'deviceId': deviceId,
      });
      final data = result.data;
      final sessionToken = data['sessionToken'] as String?;
      if (sessionToken == null || sessionToken.isEmpty) {
        throw FirebaseFunctionsException(
          code: 'internal',
          message: 'Session token was not returned by the backend.',
        );
      }
      await _persistLocalSession(
        deviceId: deviceId,
        sessionToken: sessionToken,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        final details = e.details;
        final existingDeviceId = details is Map
            ? details['existingDeviceId'] as String?
            : null;
        throw _SessionConflict(existingDeviceId ?? '');
      }
      rethrow;
    }
  }

  Future<_OverrideSessionResponse> _overrideSession({
    required String uid,
    required String newDeviceId,
  }) async {
    final callable = _functions.httpsCallable(
      'overrideSession',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final result = await callable.call<Map<Object?, Object?>>({
      'userId': uid,
      'newDeviceId': newDeviceId,
    });
    final data = result.data;
    final status = data['status'] as String?;
    final swapId = data['swapId'] as String?;
    final sessionToken = data['sessionToken'] as String?;
    final deviceId = data['deviceId'] as String?;
    final role = UserRole.fromString((data['role'] as String?) ?? 'student');
    if (status != 'completed' ||
        swapId == null ||
        swapId.isEmpty ||
        sessionToken == null ||
        sessionToken.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Session swap did not complete.',
      );
    }
    return _OverrideSessionResponse(
      swapId: swapId,
      deviceId: deviceId,
      sessionToken: sessionToken,
      role: role,
    );
  }

  Future<void> _watchSwapUntilCompleted({
    required String uid,
    required String swapId,
  }) async {
    final stream = _db
        .collection('users')
        .doc(uid)
        .collection('sessionSwaps')
        .doc(swapId)
        .snapshots();

    await for (final doc in stream.timeout(const Duration(seconds: 15))) {
      final data = doc.data();
      final status = data?['status'] as String?;
      if (status == 'completed') return;
      if (status == 'failed' || status == 'expired') {
        throw FirebaseFunctionsException(
          code: status ?? 'internal',
          message: data?['message'] as String? ?? 'Session swap failed.',
        );
      }
    }
  }

  Future<void> _persistLocalSession({
    required String deviceId,
    required String sessionToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceIdKey, deviceId);
    await prefs.setString(_kSessionTokenKey, sessionToken);
  }
}

final class _SessionConflict implements Exception {
  const _SessionConflict(this.existingDeviceId);
  final String existingDeviceId;
}

final class _OverrideSessionResponse {
  const _OverrideSessionResponse({
    required this.swapId,
    required this.deviceId,
    required this.sessionToken,
    required this.role,
  });

  final String swapId;
  final String deviceId;
  final String sessionToken;
  final UserRole role;
}
