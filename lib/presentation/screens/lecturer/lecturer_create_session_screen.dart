import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerCreateSessionScreen extends ConsumerStatefulWidget {
  const LecturerCreateSessionScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  ConsumerState<LecturerCreateSessionScreen> createState() =>
      _LecturerCreateSessionScreenState();
}

class _LecturerCreateSessionScreenState
    extends ConsumerState<LecturerCreateSessionScreen> {
  String? _courseId;
  int _durationMinutes = 60;
  double _radius = AppConstants.defaultLocationRadiusMeters;
  bool _creating = false;
  AttendanceSession? _activeSession;
  Timer? _qrRefreshTimer;

  @override
  void dispose() {
    _qrRefreshTimer?.cancel();
    super.dispose();
  }

  void _startQrRefresh(String sessionId) {
    _qrRefreshTimer?.cancel();
    _qrRefreshTimer = Timer.periodic(
      const Duration(seconds: AppConstants.qrValiditySeconds - 5),
      (_) async {
        if (_activeSession != null && _activeSession!.isActive) {
          await ref
              .read(attendanceRepositoryProvider)
              .refreshQrToken(sessionId);
        }
      },
    );
  }

  Future<void> _createSession() async {
    if (_courseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a course')));
      return;
    }

    setState(() => _creating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      final now = DateTime.now();
      final session = await ref
          .read(attendanceRepositoryProvider)
          .createSession(
            courseId: _courseId!,
            lecturerId: widget.lecturerId,
            startTime: now,
            endTime: now.add(Duration(minutes: _durationMinutes)),
            latitude: position.latitude,
            longitude: position.longitude,
            locationRadiusMeters: _radius,
          );
      setState(() => _activeSession = session);
      _startQrRefresh(session.id);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _endSession() async {
    if (_activeSession == null) return;
    await ref.read(attendanceRepositoryProvider).endSession(_activeSession!.id);
    _qrRefreshTimer?.cancel();
    setState(() => _activeSession = null);
  }

  @override
  Widget build(BuildContext context) {
    final lecturerAsync = ref.watch(_lecturerProvider(widget.lecturerId));
    final coursesAsync = ref.watch(_allCoursesProvider);

    final session = _activeSession;
    if (session != null) {
      return _ActiveSessionView(
        sessionId: session.id,
        initialSession: session,
        onEnd: _endSession,
      );
    }

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: lecturerAsync.when(
        data: (lecturer) {
          return coursesAsync.when(
            data: (allCourses) {
              final courses = lecturer == null
                  ? <Course>[]
                  : allCourses
                        .where((c) => lecturer.courseIds.contains(c.id))
                        .toList();
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Attendance Session',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _courseId,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: courses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _courseId = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Duration: $_durationMinutes min'),
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      label: '$_durationMinutes',
                      onChanged: (v) =>
                          setState(() => _durationMinutes = v.round()),
                    ),
                    Text('Location radius: ${_radius.toInt()} m'),
                    Slider(
                      value: _radius,
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '${_radius.toInt()} m',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _creating ? null : _createSession,
                      child: _creating
                          ? const CircularProgressIndicator()
                          : const Text('Start Session & Show QR'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
      ),
        ),
      ),
    );
  }
}

class _ActiveSessionView extends ConsumerWidget {
  const _ActiveSessionView({
    required this.sessionId,
    required this.initialSession,
    required this.onEnd,
  });

  final String sessionId;
  final AttendanceSession initialSession;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(_sessionProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        final s = session ?? initialSession;
        final payload = QrPayload(sessionId: s.id, token: s.qrToken).encode();
        final secondsLeft = s.qrExpiresAt.difference(DateTime.now()).inSeconds;

        return SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    Text(
                      'Scan to mark attendance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR refreshes in ${secondsLeft.clamp(0, 999)}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: payload,
                      size: (MediaQuery.of(context).size.width * 0.75)
                          .clamp(260.0, 340.0),
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Radius: ${s.locationRadiusMeters.toInt()}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onEnd,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
    );
  }
}

final _lecturerProvider = FutureProvider.family<Lecturer?, String>((ref, uid) {
  return ref.watch(catalogRepositoryProvider).getLecturer(uid);
});

final _allCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _sessionProvider = StreamProvider.family<AttendanceSession?, String>((
  ref,
  id,
) {
  return ref.watch(attendanceRepositoryProvider).watchSession(id);
});
