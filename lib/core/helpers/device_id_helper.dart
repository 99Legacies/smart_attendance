import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns a stable device identifier that persists across restarts.
///
/// Web: SHA-256 of browser fingerprint, persisted in localStorage via
/// SharedPreferences (which uses window.localStorage on the web platform).
/// Android: androidInfo.id (ANDROID_ID).
/// iOS: identifierForVendor.
Future<String> getDeviceId() async {
  if (kIsWeb) {
    return _webDeviceId();
  }
  try {
    final plugin = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await plugin.androidInfo;
      return info.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await plugin.iosInfo;
      return info.identifierForVendor ?? 'ios-unknown';
    }
  } catch (_) {}
  return 'unknown-device';
}

Future<String> _webDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('__did');
  if (cached != null && cached.isNotEmpty) return cached;

  final plugin = DeviceInfoPlugin();
  final web = await plugin.webBrowserInfo;
  final raw =
      '${web.userAgent ?? ''}|${web.vendor ?? ''}|${web.platform ?? ''}|${DateTime.now().timeZoneName}';
  final hash = sha256.convert(utf8.encode(raw)).toString();
  await prefs.setString('__did', hash);
  return hash;
}
