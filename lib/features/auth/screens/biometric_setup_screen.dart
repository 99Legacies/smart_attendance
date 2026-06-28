import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_attendance/core/helpers/biometric_helper.dart';

/// Shown once after first successful login when biometric hardware is available
/// and the user has not yet opted in.
///
/// The caller is responsible for checking [isBiometricAvailable()] and
/// whether [biometricEnabled == false] before pushing this screen. It should
/// NOT be shown on web (biometrics are not supported there).
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key, required this.uid});

  final String uid;

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _loading = false;

  Future<void> _enable() async {
    setState(() => _loading = true);
    try {
      await setBiometricEnabled(widget.uid, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric login enabled.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enable biometrics: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dismiss() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    // Guard: never render on web — caller should not push this screen on web,
    // but we add a defensive check here.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _dismiss());
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.fingerprint,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Enable Biometric Login?',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Use your fingerprint or Face ID to log in faster and more '
                'securely.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: _loading ? null : _enable,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enable'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _dismiss,
                child: const Text('Not Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
