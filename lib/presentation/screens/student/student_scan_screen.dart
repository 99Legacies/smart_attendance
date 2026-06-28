import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class StudentScanScreen extends ConsumerStatefulWidget {
  const StudentScanScreen({super.key, required this.studentUid});

  final String studentUid;

  @override
  ConsumerState<StudentScanScreen> createState() => _StudentScanScreenState();
}

class _StudentScanScreenState extends ConsumerState<StudentScanScreen> {
  bool _processing = false;
  String? _lastMessage;
  bool _success = false;
  Future<void> _onScan(String raw) async {
    if (_processing) return;
    final payload = QrPayload.tryParse(raw);
    if (payload == null) {
      setState(() {
        _success = false;
        _lastMessage = 'Invalid QR format. Scan the code shown by your lecturer.';
      });
      return;
    }

    setState(() {
      _processing = true;
      _lastMessage = null;
    });

    try {
      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      final record = await ref.read(markAttendanceUseCaseProvider).execute(
            studentUid: widget.studentUid,
            qrPayload: payload,
            latitude: position.latitude,
            longitude: position.longitude,
            deviceId: deviceId,
          );
      if (!mounted) return;
      setState(() {
        _success = true;
        _lastMessage =
            'Attendance marked: ${record.status.label} at ${record.timestamp}';
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _lastMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _lastMessage = 'Failed to mark attendance. Check GPS and try again.';
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        children: [
          if (_lastMessage != null)
            AppCard(
              child: Row(
                children: [
                  Icon(
                    _success ? Icons.check_circle : Icons.error_outline,
                    color: _success ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_lastMessage!)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                child: kIsWeb
                    ? _WebScanFallback(onManualSubmit: _onScan)
                    : Stack(
                        children: [
                          MobileScanner(
                            onDetect: (capture) {
                              final barcodes = capture.barcodes;
                              for (final b in barcodes) {
                                final raw = b.rawValue;
                                if (raw != null) {
                                  _onScan(raw);
                                  break;
                                }
                              }
                            },
                          ),
                          if (_processing)
                            const ColoredBox(
                              color: Colors.black38,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Point your camera at the lecturer\'s QR code. '
            'You must be on campus within the allowed radius.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WebScanFallback extends StatefulWidget {
  const _WebScanFallback({required this.onManualSubmit});

  final Future<void> Function(String) onManualSubmit;

  @override
  State<_WebScanFallback> createState() => _WebScanFallbackState();
}

class _WebScanFallbackState extends State<_WebScanFallback> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Web: paste QR payload from scanner app or enter sessionId|token',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'QR Payload',
              hintText: 'sessionId|token',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.onManualSubmit(_controller.text.trim()),
            child: const Text('Submit Attendance'),
          ),
        ],
      ),
    );
  }
}
