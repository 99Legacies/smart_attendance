import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance/core/helpers/device_id_helper.dart';
import 'package:smart_attendance/core/helpers/distance_helper.dart';

sealed class AttendanceResult {
  const AttendanceResult();
}

final class AttendanceSuccess extends AttendanceResult {
  const AttendanceSuccess({required this.recordId});
  final String recordId;
}

final class AttendanceFailure extends AttendanceResult {
  const AttendanceFailure({required this.reason});
  final String reason;
}

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Validates the scanned [qrPayload] (JSON string) against Firestore,
  /// checks GPS proximity, then atomically marks the session used and writes
  /// an attendance record.
  Future<AttendanceResult> submitAttendance(String qrPayload) async {
    // ── Parse QR payload ────────────────────────────────────────────────────
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(qrPayload) as Map<String, dynamic>;
    } catch (_) {
      return const AttendanceFailure(reason: 'Invalid QR code format.');
    }

    final sessionId = parsed['sessionId'] as String?;
    final token = parsed['token'] as String?;
    if (sessionId == null || token == null) {
      return const AttendanceFailure(reason: 'Invalid QR code format.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AttendanceFailure(reason: 'Not authenticated.');
    }

    // ── Fetch session ────────────────────────────────────────────────────────
    final sessionRef = _db.collection('attendance_sessions').doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      return const AttendanceFailure(reason: 'QR code is invalid or expired.');
    }
    final sd = sessionSnap.data()!;

    // ── Token match ──────────────────────────────────────────────────────────
    if (sd['token'] != token) {
      return const AttendanceFailure(reason: 'QR code is invalid.');
    }

    // ── Expiry ───────────────────────────────────────────────────────────────
    final expiresAt = (sd['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      return const AttendanceFailure(
        reason: 'QR code has expired. Ask your lecturer to regenerate it.',
      );
    }

    // ── One-time use ─────────────────────────────────────────────────────────
    if (sd['used'] == true) {
      return const AttendanceFailure(
        reason: 'This QR code has already been used.',
      );
    }

    // ── Duplicate submission check ───────────────────────────────────────────
    final duplicate = await _db
        .collection('attendance_records')
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      return const AttendanceFailure(
        reason: 'You have already submitted attendance for this session.',
      );
    }

    // ── Get GPS ──────────────────────────────────────────────────────────────
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      return AttendanceFailure(reason: 'Could not get location: $e');
    }

    // ── Mock location (Android) ──────────────────────────────────────────────
    if (!kIsWeb && position.isMocked) {
      return const AttendanceFailure(reason: 'Mock location detected.');
    }

    // ── GPS accuracy ─────────────────────────────────────────────────────────
    if (position.accuracy > 30) {
      return const AttendanceFailure(
        reason: 'GPS accuracy is too low. Move to an open area and try again.',
      );
    }

    // ── Distance (Haversine) ─────────────────────────────────────────────────
    final sessionLat = (sd['latitude'] as num).toDouble();
    final sessionLng = (sd['longitude'] as num).toDouble();
    final allowedRadius = (sd['allowedRadius'] as num).toDouble();
    final distance = haversineDistance(
      position.latitude,
      position.longitude,
      sessionLat,
      sessionLng,
    );
    if (distance > allowedRadius) {
      return AttendanceFailure(
        reason:
            'You are too far from the class location '
            '(${distance.toStringAsFixed(0)}m away, limit: ${allowedRadius.toInt()}m).',
      );
    }

    // ── Web GPS timestamp drift (warn, do not hard-reject) ───────────────────
    if (kIsWeb) {
      final drift = DateTime.now()
          .difference(
            DateTime.fromMillisecondsSinceEpoch(
              position.timestamp.millisecondsSinceEpoch,
            ),
          )
          .inSeconds
          .abs();
      // Drift > 10 s on web is common; log and continue.
      if (drift > 10) {
        // ignore: avoid_print
        print('[AttendanceService] web GPS drift: ${drift}s');
      }
    }

    final deviceId = await getDeviceId();

    // ── Atomic transaction ───────────────────────────────────────────────────
    final recordRef = _db.collection('attendance_records').doc();
    try {
      await _db.runTransaction((tx) async {
        final fresh = await tx.get(sessionRef);
        if (fresh.data()?['used'] == true) {
          throw _AlreadyUsedException();
        }
        tx.update(sessionRef, {'used': true});
        tx.set(recordRef, {
          'sessionId': sessionId,
          'studentId': user.uid,
          'scannedAt': FieldValue.serverTimestamp(),
          'deviceId': deviceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'gpsAccuracy': position.accuracy,
          'status': 'present',
          'rejectReason': null,
        });
      });
    } on _AlreadyUsedException {
      return const AttendanceFailure(
        reason: 'This QR code has already been used.',
      );
    } catch (e) {
      return AttendanceFailure(reason: 'Failed to record attendance: $e');
    }

    return AttendanceSuccess(recordId: recordRef.id);
  }
}

class _AlreadyUsedException implements Exception {}
