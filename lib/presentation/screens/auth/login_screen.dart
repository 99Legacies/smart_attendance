import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/helpers/biometric_helper.dart';
import 'package:smart_attendance/core/utils/role_routes.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/core/widgets/dialogs/biometric_failed_dialog.dart';
import 'package:smart_attendance/core/widgets/dialogs/device_conflict_dialog.dart';
import 'package:smart_attendance/core/widgets/password_text_field.dart';
import 'package:smart_attendance/features/auth/screens/biometric_setup_screen.dart';
import 'package:smart_attendance/features/auth/services/auth_service.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/router/app_router.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_auth_layout.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_buttons.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.logoutReason});

  final String? logoutReason;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService? _authServiceInstance;
  bool _loading = false;
  String? _error;

  AuthService get _authService => _authServiceInstance ??= AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.logoutReason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You were signed out: ${widget.logoutReason}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  LoginDialogActiveNotifier get _dialogBlock =>
      ref.read(loginDialogActiveProvider.notifier);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    _dialogBlock.activate();

    try {
      final result = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      await _handleResult(result);
    } catch (e) {
      _dialogBlock.deactivate();
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResult(LoginResult result) async {
    switch (result) {
      case LoginSuccess(:final uid, :final role):
        _dialogBlock.deactivate();
        if (!mounted) return;
        context.go(RoleRoutes.homeFor(role));
        _scheduleBiometricSetup(uid);

      case LoginDeviceConflict():
        final result = await showDeviceConflictDialog(
          context,
          authService: _authService,
        );
        if (!mounted) return;

        if (result != null) {
          await _handleResult(result);
        } else {
          await _authService.signOut();
          _dialogBlock.deactivate();
          setState(() => _error = null);
        }

      case LoginBiometricFailed(:final uid):
        final action = await showBiometricFailedDialog(context);
        if (!mounted) return;

        _dialogBlock.deactivate();
        if (action == BiometricFailedAction.tryAgain) {
          _scheduleBiometricSetup(uid);
        }
    }
  }

  void _scheduleBiometricSetup(String uid) {
    if (kIsWeb) return;
    Future.delayed(const Duration(milliseconds: 500), () async {
      final available = await isBiometricAvailable();
      final enabled = await isBiometricEnabledForUser(uid);
      if (!available || enabled) return;
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => BiometricSetupScreen(uid: uid)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApScaffold(
      body: ApAuthLayout(
        title: 'Welcome back',
        subtitle: 'Sign in to mark or manage attendance',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ApAuthBanner(message: _error!),
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _dialogBlock.deactivate();
                    context.push('/forgot-password');
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              ApPrimaryButton(
                label: 'Sign In',
                loading: _loading,
                icon: Icons.login_rounded,
                onPressed: _loading ? null : _login,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'New here?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
