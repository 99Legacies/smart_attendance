import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(Validators.email('   '), isNotNull);
    });

    test('returns error for missing @', () {
      expect(Validators.email('userexample.com'), isNotNull);
    });

    test('returns error for missing domain', () {
      expect(Validators.email('user@'), isNotNull);
    });

    test('returns error for missing TLD', () {
      expect(Validators.email('user@example'), isNotNull);
    });

    test('accepts valid university email', () {
      expect(Validators.email('kwame@university.edu'), isNull);
    });

    test('accepts valid gmail address', () {
      expect(Validators.email('test.user@gmail.com'), isNull);
    });

    test('trims whitespace before validating', () {
      expect(Validators.email('  user@school.edu  '), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.password(''), isNotNull);
    });

    test('returns error for fewer than 8 characters', () {
      expect(Validators.password('Abc1'), isNotNull);
    });

    test('returns error when missing uppercase letter', () {
      expect(Validators.password('abcdefg1'), isNotNull);
    });

    test('returns error when missing lowercase letter', () {
      expect(Validators.password('ABCDEFG1'), isNotNull);
    });

    test('returns error when missing digit', () {
      expect(Validators.password('Abcdefgh'), isNotNull);
    });

    test('accepts valid strong password', () {
      expect(Validators.password('Secure12'), isNull);
    });

    test('accepts longer valid password', () {
      expect(Validators.password('MyPass123!'), isNull);
    });
  });

  group('Validators.requiredField', () {
    test('returns error for null', () {
      expect(Validators.requiredField(null, 'Name'), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.requiredField('', 'Name'), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(Validators.requiredField('   ', 'Name'), isNotNull);
    });

    test('includes field name in the error message', () {
      final error = Validators.requiredField('', 'Department');
      expect(error, contains('Department'));
    });

    test('returns null for non-empty value', () {
      expect(Validators.requiredField('Computer Science', 'Department'), isNull);
    });
  });

  group('Validators.studentId', () {
    test('returns error for null', () {
      expect(Validators.studentId(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.studentId(''), isNotNull);
    });

    test('returns error for less than 3 characters', () {
      expect(Validators.studentId('AB'), isNotNull);
    });

    test('accepts valid 3-character ID', () {
      expect(Validators.studentId('AB1'), isNull);
    });

    test('accepts longer ID', () {
      expect(Validators.studentId('STU2023001'), isNull);
    });
  });

  group('Validators.lecturerId', () {
    test('returns error for null', () {
      expect(Validators.lecturerId(null), isNotNull);
    });

    test('returns error for short ID', () {
      expect(Validators.lecturerId('AB'), isNotNull);
    });

    test('accepts valid 3-character ID', () {
      expect(Validators.lecturerId('LEC'), isNull);
    });
  });
}
