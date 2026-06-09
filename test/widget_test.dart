import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';

void main() {
  test('email validator rejects invalid email', () {
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('user@school.edu'), isNull);
  });

  test('QR payload parse', () {
    final payload = QrPayload.tryParse('session123|token456');
    expect(payload?.sessionId, 'session123');
    expect(payload?.token, 'token456');
    expect(QrPayload.tryParse('invalid'), isNull);
  });
}
