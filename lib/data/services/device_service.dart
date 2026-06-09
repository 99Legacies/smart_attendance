import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Resolves a stable device identifier for anti-cheat validation.
class DeviceService {
  DeviceService({DeviceInfoPlugin? plugin}) : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> getDeviceId() async {
    if (kIsWeb) {
      final web = await _plugin.webBrowserInfo;
      return 'web-${web.vendor}-${web.userAgent?.hashCode ?? 0}';
    }
    try {
      final android = await _plugin.androidInfo;
      return android.id;
    } catch (_) {}
    try {
      final ios = await _plugin.iosInfo;
      return ios.identifierForVendor ?? 'ios-unknown';
    } catch (_) {}
    return 'unknown-device';
  }
}
