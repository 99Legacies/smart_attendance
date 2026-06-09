import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String department,
    required UserRole role,
    required String roleId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final repo = ref.read(authRepositoryProvider);

      if (role == UserRole.student) {
        await repo.registerStudent(
          fullName: fullName,
          studentId: roleId,
          email: email,
          password: password,
          departmentName: department,
          courseIds: const [],
          deviceId: deviceId,
        );
      } else if (role == UserRole.lecturer) {
        await repo.registerLecturer(
          fullName: fullName,
          lecturerId: roleId,
          email: email,
          password: password,
          departmentName: department,
          courseIds: const [],
        );
      } else {
        throw const AppException(
          'Registration is only available for Student or Lecturer roles.',
          code: 'invalid_role',
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
