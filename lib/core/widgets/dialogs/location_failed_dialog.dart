import 'package:flutter/material.dart';

/// Shows a dialog explaining why location/attendance verification failed.
///
/// Pass the specific [reason] string from [AttendanceFailure.reason] so the
/// user sees an actionable message rather than a generic error.
Future<void> showLocationFailedDialog(
  BuildContext context, {
  required String reason,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LocationFailedDialog(reason: reason),
  );
}

class _LocationFailedDialog extends StatelessWidget {
  const _LocationFailedDialog({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.location_off,
        size: 40,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Location Verification Failed'),
      content: Text(reason),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
