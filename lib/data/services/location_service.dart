import 'package:geolocator/geolocator.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';

/// Wraps Geolocator for GPS attendance validation.
class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const AppException(
        'Location services are disabled. Enable GPS to mark attendance.',
        code: 'location_disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Location permission denied. Grant access to mark attendance.',
        code: 'location_denied',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
