import 'package:flutter/material.dart';
import 'package:smart_attendance/features/auth/services/auth_service.dart';

/// Shows an alert informing the user their account is active on another device.
///
/// Calls [AuthService.forceLogin] if the user taps "Continue" and only pops
/// after the Firestore rebind completes. Returns the [LoginResult] so the
/// caller can continue through [_handleResult], or null if the user cancelled.
Future<LoginResult?> showDeviceConflictDialog(
  BuildContext context, {
  required AuthService authService,
}) {
  return showDialog<LoginResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeviceConflictDialog(authService: authService),
  );
}

class _DeviceConflictDialog extends StatefulWidget {
  const _DeviceConflictDialog({required this.authService});

  final AuthService authService;

  @override
  State<_DeviceConflictDialog> createState() => _DeviceConflictDialogState();
}

class _DeviceConflictDialogState extends State<_DeviceConflictDialog> {
  bool _isLoading = false;

  Future<void> _continue() async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.authService.forceLogin();
      if (!mounted) return;
      // Pop with the LoginResult — caller passes it straight into _handleResult.
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to switch device. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.devices_other, size: 40),
      title: const Text('Account Already Active on Another Device'),
      content: const Text(
        'Your account is currently logged in on another device. '
        'Continuing will sign out that device immediately.',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _continue,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue'),
        ),
      ],
    );
  }
}
