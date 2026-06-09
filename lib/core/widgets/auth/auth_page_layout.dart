import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';

/// Shared layout for login, register, and forgot-password screens.
class AuthPageLayout extends ConsumerWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.maxWidth = 440,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double maxWidth;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  _AuthLogo(isDark: isDark),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _AuthGlassCard(child: child),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            tooltip: 'Toggle theme',
          ),
        ),
        if (showBack)
          Positioned(
            top: 8,
            left: 4,
            child: IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              tooltip: 'Back',
            ),
          ),
      ],
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isDark
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [Colors.white, Colors.white.withValues(alpha: 0.85)],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppTheme.primary,
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 40,
          color: isDark ? Colors.white : AppTheme.primary,
        ),
      ),
    );
  }
}

class _AuthGlassCard extends StatelessWidget {
  const _AuthGlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
