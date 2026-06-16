import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';

void main() {
  group('QrPayload.tryParse', () {
    test('parses valid pipe-separated payload', () {
      final payload = QrPayload.tryParse('session123|token456');
      expect(payload, isNotNull);
      expect(payload!.sessionId, 'session123');
      expect(payload.token, 'token456');
    });

    test('returns null for payload without pipe separator', () {
      expect(QrPayload.tryParse('invalidsessiontoken'), isNull);
    });

    test('returns null for empty string', () {
      expect(QrPayload.tryParse(''), isNull);
    });

    test('returns null when more than one pipe is present', () {
      expect(QrPayload.tryParse('a|b|c'), isNull);
    });

    test('encode round-trips through tryParse', () {
      const original = QrPayload(sessionId: 'abc', token: 'xyz');
      final encoded = original.encode();
      final parsed = QrPayload.tryParse(encoded);
      expect(parsed?.sessionId, 'abc');
      expect(parsed?.token, 'xyz');
    });

    test('accepts UUIDs as sessionId and token', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final payload = QrPayload.tryParse('$uuid|$uuid');
      expect(payload?.sessionId, uuid);
      expect(payload?.token, uuid);
    });
  });
}
