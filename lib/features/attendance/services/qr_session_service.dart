import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class QrSessionService {
  QrSessionService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Creates a one-time 60-second attendance session in Firestore and returns
  /// the JSON-encoded QR payload string for the caller to render via qr_flutter.
  Future<String> generateQrSession({
    required double lat,
    required double lng,
    double radiusMeters = 50,
  }) async {
    final sessionId = const Uuid().v4();
    final token = _generateToken();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(seconds: 60)),
    );

    await _db.collection('attendance_sessions').doc(sessionId).set({
      'createdBy': uid,
      'latitude': lat,
      'longitude': lng,
      'allowedRadius': radiusMeters,
      'token': token,
      'expiresAt': expiresAt,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return jsonEncode({
      'sessionId': sessionId,
      'token': token,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static String _generateToken() {
    final rand = Random.secure();
    return List.generate(8, (_) => rand.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
