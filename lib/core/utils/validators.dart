/// Input validation helpers.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? studentId(String? value) {
    final base = requiredField(value, 'Student ID');
    if (base != null) return base;
    if (value!.trim().length < 3) {
      return 'Student ID must be at least 3 characters';
    }
    return null;
  }

  static String? lecturerId(String? value) {
    final base = requiredField(value, 'Lecturer ID');
    if (base != null) return base;
    if (value!.trim().length < 3) {
      return 'Lecturer ID must be at least 3 characters';
    }
    return null;
  }
}
