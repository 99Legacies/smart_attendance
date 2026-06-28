import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_attendance/features/attendance/services/qr_session_service.dart';

class LecturerQrScreen extends StatefulWidget {
  const LecturerQrScreen({super.key});

  @override
  State<LecturerQrScreen> createState() => _LecturerQrScreenState();
}

class _LecturerQrScreenState extends State<LecturerQrScreen> {
  final _service = QrSessionService();

  String? _qrPayload;
  int _secondsLeft = 60;
  double _radius = 50;
  double? _lat;
  double? _lng;
  bool _loading = false;
  String? _error;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _loading = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location services are disabled.');

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      await _generate();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_lat == null || _lng == null) return;
    _countdownTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = await _service.generateQrSession(
        lat: _lat!,
        lng: _lng!,
        radiusMeters: _radius,
      );
      if (!mounted) return;
      setState(() {
        _qrPayload = payload;
        _secondsLeft = 60;
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _generate();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiringSoon = _secondsLeft <= 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance QR Code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_lat != null && _lng != null)
              Text(
                'Location: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Allowed radius: '),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _radius,
                  items: const [
                    DropdownMenuItem(value: 25, child: Text('25 m')),
                    DropdownMenuItem(value: 50, child: Text('50 m')),
                    DropdownMenuItem(value: 100, child: Text('100 m')),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) {
                          if (v != null) setState(() => _radius = v);
                        },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_qrPayload != null && !_loading) ...[
              Center(
                child: QrImageView(
                  data: _qrPayload!,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Expires in $_secondsLeft s',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: expiringSoon
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _secondsLeft / 60,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: expiringSoon
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate Now'),
            ),
          ],
        ),
      ),
    );
  }
}
