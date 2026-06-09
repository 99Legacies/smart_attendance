import 'package:flutter/material.dart';

enum AuthBannerType { error, success, info }

/// Inline banner for auth form feedback.
class AuthBanner extends StatelessWidget {
  const AuthBanner({
    super.key,
    required this.message,
    this.type = AuthBannerType.error,
  });

  final String message;
  final AuthBannerType type;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (type) {
      AuthBannerType.error => (
          Icons.error_outline_rounded,
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
      AuthBannerType.success => (
          Icons.check_circle_outline_rounded,
          Colors.green.shade50,
          Colors.green.shade900,
        ),
      AuthBannerType.info => (
          Icons.info_outline_rounded,
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.onPrimaryContainer,
        ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
