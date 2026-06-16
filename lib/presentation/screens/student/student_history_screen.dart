import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_loading.dart';

class StudentHistoryScreen extends ConsumerWidget {
  const StudentHistoryScreen({super.key, required this.studentUid});

  final String studentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(_studentRecordsProvider(studentUid));

    return Padding(
      padding: AppTheme.screenPadding,
      child: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No attendance records yet.'));
          }
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = records[i];
              return AppCard(
                child: ListTile(
                  leading: _statusIcon(r.status.name),
                  title: Text(r.status.label),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(r.timestamp),
                  ),
                  trailing: Text(
                    r.courseId ?? r.sessionId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const ApLoadingList(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load attendance history'),
              const SizedBox(height: 4),
              Text(
                'Please check your connection and try again.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'present':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'late':
        return const Icon(Icons.schedule, color: Colors.orange);
      default:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }
}

final _studentRecordsProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, uid) {
      return ref
          .watch(attendanceRepositoryProvider)
          .watchRecordsForStudent(uid);
    });
