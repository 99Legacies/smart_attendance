import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// System chrome styling aligned with gradient shells and transparent app bars.
abstract final class AppSystemUi {
  static SystemUiOverlayStyle overlayForGradient({required bool isDark}) {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  static void applyGradientOverlay({required bool isDark}) {
    SystemChrome.setSystemUIOverlayStyle(overlayForGradient(isDark: isDark));
  }
}
