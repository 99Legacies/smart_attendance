import 'package:flutter/material.dart';
import 'package:smart_attendance/core/helpers/biometric_helper.dart';

enum BiometricFailedAction { tryAgain, usePassword }

/// Shows a dialog when biometric authentication fails.
///
/// "Try Again" re-prompts the biometric immediately inside the dialog.
/// "Use Password" returns [BiometricFailedAction.usePassword] so the caller
/// can skip biometric for this session without writing to Firestore.
Future<BiometricFailedAction?> showBiometricFailedDialog(
  BuildContext context,
) {
  return showDialog<BiometricFailedAction>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _BiometricFailedDialog(),
  );
}

class _BiometricFailedDialog extends StatefulWidget {
  const _BiometricFailedDialog();

  @override
  State<_BiometricFailedDialog> createState() => _BiometricFailedDialogState();
}

class _BiometricFailedDialogState extends State<_BiometricFailedDialog> {
  bool _retrying = false;

  Future<void> _tryAgain() async {
    setState(() => _retrying = true);
    final passed = await authenticate(
      reason: 'Confirm your identity to continue',
    );
    if (!mounted) return;
    setState(() => _retrying = false);
    if (passed) {
      // Biometric succeeded on retry — treat same as tryAgain action so the
      // caller knows to proceed normally.
      Navigator.of(context).pop(BiometricFailedAction.tryAgain);
    }
    // If still failing, stay in the dialog so the user can choose Use Password.
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 40),
      title: const Text('Biometric Verification Failed'),
      content: const Text(
        'We could not verify your identity. '
        'Please try again or use your password.',
      ),
      actions: [
        TextButton(
          onPressed: _retrying
              ? null
              : () => Navigator.of(context).pop(BiometricFailedAction.usePassword),
          child: const Text('Use Password'),
        ),
        FilledButton(
          onPressed: _retrying ? null : _tryAgain,
          child: _retrying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Try Again'),
        ),
      ],
    );
  }
}
