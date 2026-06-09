import 'package:flutter/material.dart';
import 'package:smart_attendance/core/widgets/secondary_screen_scaffold.dart';

/// Consistent navigation for secondary (pushed) screens.
abstract final class AppNavigation {
  /// Pushes a screen that already includes its own scaffold (e.g. [NotificationsScreen]).
  static Future<T?> pushRoute<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Pushes content with exactly one gradient scaffold and themed app bar.
  static Future<T?> pushSecondary<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            SecondaryScreenScaffold(
              title: title,
              body: body,
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
            ),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
