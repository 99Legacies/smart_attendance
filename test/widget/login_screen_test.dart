import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/auth/login_screen.dart';

// ─── Fake auth repository ─────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.throwOnSignIn});

  final Exception? throwOnSignIn;
  bool signInCalled = false;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required String deviceId,
    bool enforceSingleDevice = false,
  }) async {
    signInCalled = true;
    if (throwOnSignIn != null) throw throwOnSignIn!;
    return AuthUser(uid: 'uid1', email: email, role: UserRole.student);
  }

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String department,
    UserRole role = UserRole.student,
    required String deviceId,
    String roleId = '',
  }) => throw UnimplementedError();

  @override
  Future<AuthUser> registerStudent({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
    required String deviceId,
  }) => throw UnimplementedError();

  @override
  Future<AuthUser> registerLecturer({
    required String fullName,
    required String lecturerId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<UserRole> resolveRole(String uid) async => UserRole.student;
}

// ─── Fake device service ──────────────────────────────────────────────────────

class _FakeDeviceService {
  Future<String> getDeviceId() async => 'test-device-id';
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

Widget _wrapLoginScreen(AuthRepository repo) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student-dashboard',
        builder: (_, _) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      deviceServiceProvider.overrideWith(
        (ref) => _FakeDeviceService() as dynamic,
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen — form validation', () {
    testWidgets('shows email error when email field is empty', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen(_FakeAuthRepository()));
      await tester.pumpAndSettle();

      // Tap Sign In without filling anything
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows email format error for invalid email', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen(_FakeAuthRepository()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('does not call signIn when form is invalid', (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(_wrapLoginScreen(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(repo.signInCalled, isFalse);
    });
  });

  group('LoginScreen — error handling', () {
    testWidgets('shows AppException message on sign-in failure', (tester) async {
      final repo = _FakeAuthRepository(
        throwOnSignIn: const AppException('Invalid email or password.'),
      );
      await tester.pumpWidget(_wrapLoginScreen(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'WrongPass1',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('shows generic message on unexpected error', (tester) async {
      final repo = _FakeAuthRepository(
        throwOnSignIn: Exception('network error'),
      );
      await tester.pumpWidget(_wrapLoginScreen(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'ValidPass1',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login failed. Please try again.'), findsOneWidget);
      // Raw exception must not be shown
      expect(find.textContaining('network error'), findsNothing);
    });
  });

  group('LoginScreen — navigation', () {
    testWidgets('Sign In button is present', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen(_FakeAuthRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Forgot password link is present', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen(_FakeAuthRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('Create an account button is present', (tester) async {
      await tester.pumpWidget(_wrapLoginScreen(_FakeAuthRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Create an account'), findsOneWidget);
    });
  });
}
