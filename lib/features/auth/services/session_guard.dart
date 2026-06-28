import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attendance/data/local/session_cache_service.dart';

/// Periodically verifies that the locally stored session token still matches
/// the one in Firestore. Logs out and fires [onSessionInvalidated] if another
/// device has taken over the session.
///
/// Usage (call once per login):
///   SessionGuard.start(onSessionInvalidated: () { router.go('/login'); });
///   SessionGuard.stop();   // call when auth state becomes null
class SessionGuard with WidgetsBindingObserver {
  SessionGuard._({required this._onSessionInvalidated});

  final void Function() _onSessionInvalidated;
  Timer? _timer;
  bool _checking = false;

  // ── Singleton / static API ────────────────────────────────────────────────

  static SessionGuard? _instance;
  static bool _isRunning = false;
  static bool _isSuspended = false;

  /// Starts the session guard. No-op if already running.
  static void start({required void Function() onSessionInvalidated}) {
    if (_isRunning) return;
    _isRunning = true;
    _instance = SessionGuard._(onSessionInvalidated: onSessionInvalidated);
    _instance!._start();
  }

  /// Stops the guard and cleans up. Safe to call when already stopped.
  static void stop() {
    _instance?._stop();
    _instance = null;
    _isRunning = false;
  }

  static void suspend() {
    _isSuspended = true;
  }

  static void resume() {
    _isSuspended = false;
  }

  // ── Private instance implementation ──────────────────────────────────────

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
    _check(); // immediate first check
  }

  void _stop() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_isSuspended) return;
    if (_checking) return;
    _checking = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localDevice = prefs.getString(_kDeviceIdKey);
      final localToken = prefs.getString(_kSessionTokenKey);

      // Missing local session data while Firebase says we're authenticated
      // means the session was never properly bound — treat as mismatch.
      if (localDevice == null || localToken == null) {
        await SessionCacheService.clearSession();
        await FirebaseAuth.instance.signOut();
        await prefs.remove(_kDeviceIdKey);
        await prefs.remove(_kSessionTokenKey);
        _onSessionInvalidated();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final remoteDevice = data['activeDeviceId'] as String?;
      final remoteToken = data['activeSessionToken'] as String?;

      if (remoteDevice != localDevice || remoteToken != localToken) {
        // Clear session cache BEFORE signing out so the authStateChanges
        // null event does not fall back to the Hive cache and keep the
        // user "logged in" on screens where Firestore will deny every query.
        await SessionCacheService.clearSession();
        await FirebaseAuth.instance.signOut();
        await prefs.remove(_kDeviceIdKey);
        await prefs.remove(_kSessionTokenKey);
        _onSessionInvalidated();
      }
    } finally {
      _checking = false;
    }
  }

  static const _kDeviceIdKey = '_sid';
  static const _kSessionTokenKey = '_stk';
}
