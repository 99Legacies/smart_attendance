import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/data/models/attendance_session_model.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerSessionsScreen extends ConsumerWidget {
  const LecturerSessionsScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_lecturerSessionsProvider(lecturerId));

    return Padding(
      padding: AppTheme.screenPadding,
      child: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions yet.'));
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = sessions[i];
              return AppCard(
                onTap: () => _openSessionDetail(context, s.id),
                child: ListTile(
                  title: Text('Course: ${s.courseId}'),
                  subtitle: Text(
                    '${DateFormat.yMMMd().add_jm().format(s.startTime)} — '
                    '${s.isActive ? "Active" : "Ended"}',
                  ),
                  trailing: s.isActive
                      ? const Icon(Icons.circle, color: Colors.green, size: 12)
                      : const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openSessionDetail(BuildContext context, String sessionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SessionDetailSheet(sessionId: sessionId),
    );
  }
}

class _SessionDetailSheet extends ConsumerStatefulWidget {
  const _SessionDetailSheet({required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<_SessionDetailSheet> createState() =>
      _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  bool _ending = false;

  Future<void> _endSession(AttendanceSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session'),
        content: const Text(
          'End this session? Students who did not mark attendance will be '
          'marked absent and notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _ending = true);
    try {
      String? courseName;
      try {
        final courses = await ref
            .read(_allCoursesProvider.future)
            .timeout(const Duration(seconds: 5));
        for (final c in courses) {
          if (c.id == session.courseId) {
            courseName =
                c.courseCode != null ? '${c.courseCode} — ${c.name}' : c.name;
            break;
          }
        }
      } catch (_) {
        // Course name fetch timed out — proceed without it
      }
      await ref.read(attendanceRepositoryProvider).endSession(
            widget.sessionId,
            courseName: courseName,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        'Session ended. Absent students have been notified.',
      );
      Navigator.pop(context);
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live session from Firestore so isActive updates in real time
    final sessionAsync = ref.watch(_liveSessionProvider(widget.sessionId));
    final recordsAsync = ref.watch(_sessionRecordsProvider(widget.sessionId));
    final statsAsync = ref.watch(_sessionStatsProvider(widget.sessionId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(16),
        child: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (session) {
            if (session == null) {
              return const Center(child: Text('Session not found.'));
            }
            return ListView(
              controller: controller,
              children: [
                Text(
                  'Session Attendance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  session.isActive ? '🟢 Active' : '🔴 Ended',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                statsAsync.when(
                  data: (stats) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          'Present',
                          stats['present'] ?? 0,
                          Colors.green,
                        ),
                        _StatChip(
                          'Late',
                          stats['late'] ?? 0,
                          Colors.orange,
                        ),
                        _StatChip(
                          'Total',
                          stats['total'] ?? 0,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                ),
                if (session.isActive) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _ending ? null : () => _endSession(session),
                    icon: _ending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop_circle_outlined),
                    label: const Text('End session & notify absentees'),
                  ),
                ],
                const SizedBox(height: 12),
                recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('No attendance yet.'),
                      );
                    }
                    return Column(
                      children: records
                          .map(
                            (r) => ListTile(
                              title: Text(r.studentId),
                              subtitle: Text(r.status.label),
                              trailing: Text(
                                DateFormat.Hm().format(r.timestamp),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('$e'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 24, color: color)),
        Text(label),
      ],
    );
  }
}

final _allCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _lecturerSessionsProvider =
    StreamProvider.family<List<AttendanceSession>, String>((ref, lecturerId) {
      return FirebaseFirestore.instance
          .collection(AppConstants.sessionsCollection)
          .where('lecturerId', isEqualTo: lecturerId)
          .orderBy('startTime', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => AttendanceSessionModel.fromFirestore(d))
                .toList(),
          );
    });

// Watches a single session live from Firestore — updates when isActive changes
final _liveSessionProvider =
    StreamProvider.family<AttendanceSession?, String>((ref, sessionId) {
      return FirebaseFirestore.instance
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return AttendanceSessionModel.fromFirestore(doc);
          });
    });

final _sessionRecordsProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, sessionId) {
      return ref
          .watch(attendanceRepositoryProvider)
          .watchRecordsForSession(sessionId);
    });

final _sessionStatsProvider = FutureProvider.family<Map<String, int>, String>((
  ref,
  sessionId,
) {
  return ref.watch(attendanceRepositoryProvider).getSessionStats(sessionId);
});
