import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/core/widgets/firestore_department_dropdown.dart';
import 'package:smart_attendance/core/widgets/password_text_field.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/auth_controller.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_auth_layout.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_buttons.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _roleIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _department;
  UserRole _role = UserRole.student;
  String? _error;

  bool get _isStudent => _role == UserRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    _roleIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_department == null) {
      setState(() => _error = 'Please select a department');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() => _error = null);

    // Fire and forget — ref.listen in build() handles all error and success
    // feedback reactively. Do NOT wrap in try/catch here as that causes
    // double error handling and can show raw exceptions instead of friendly
    // AppException messages.
    await ref.read(authControllerProvider.notifier).register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      department: _department!,
      role: _role,
      roleId: _roleIdController.text.trim(),
    );
    // Router handles navigation automatically via authStateChanges on success.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen for errors from the provider
    // Single source of truth for auth feedback — handles both errors and
    // success. Checking previous.isLoading ensures the snackbar only fires
    // on an actual loading→data transition, not on the initial build.
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError && mounted) {
        final err = next.error;
        setState(
          () => _error = err is AppException ? err.message : err.toString(),
        );
      }
      if (previous?.isLoading == true && next is AsyncData && mounted) {
        SnackbarUtils.showSuccess(context, 'Account created successfully');
      }
    });

    return ApScaffold(
      body: ApAuthLayout(
        title: 'Create account',
        subtitle: 'Register as a student or lecturer',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ApAuthBanner(message: _error!, isError: true),

              Text(
                'Role',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.student,
                    label: Text('Student'),
                    icon: Icon(Icons.school_outlined),
                  ),
                  ButtonSegment(
                    value: UserRole.lecturer,
                    label: Text('Lecturer'),
                    icon: Icon(Icons.record_voice_over_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (selected) {
                  setState(() {
                    _role = selected.first;
                    _roleIdController.clear();
                  });
                },
              ),

              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.requiredField(v, 'Full name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleIdController,
                decoration: InputDecoration(
                  labelText: _isStudent ? 'Student ID' : 'Lecturer ID',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  hintText: _isStudent
                      ? 'e.g. STU-2024-001'
                      : 'e.g. LEC-2024-001',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.requiredField(
                  v,
                  _isStudent ? 'Student ID' : 'Lecturer ID',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'you@university.edu',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              PasswordTextField(
                controller: _passwordController,
                labelText: 'Password',
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              PasswordTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                validator: (v) =>
                    Validators.requiredField(v, 'Confirm password'),
              ),
              const SizedBox(height: 16),
              FirestoreDepartmentDropdown(
                value: _department,
                onChanged: (v) => setState(() => _department = v),
                validator: (value) =>
                    value == null ? 'Select a department' : null,
              ),
              const SizedBox(height: 24),
              ApPrimaryButton(
                label: _isStudent
                    ? 'Sign up as Student'
                    : 'Sign up as Lecturer',
                loading: authState.isLoading,
                onPressed: authState.isLoading ? null : _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
