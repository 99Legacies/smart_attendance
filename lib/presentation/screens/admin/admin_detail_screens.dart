import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/data/models/attendance_record_model.dart';
import 'package:smart_attendance/data/models/attendance_session_model.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/data/models/department_model.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/data/models/lecturer_model.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/security_log.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class AdminStudentsDetailScreen extends ConsumerWidget {
  const AdminStudentsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_studentsProvider);
    final departments = ref.watch(_departmentsProvider).asData?.value;

    return Padding(
      padding: AppTheme.screenPadding,
      child: studentsAsync.when(
        data: (students) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailHeader(
                title: 'Students',
                subtitle: 'All registered students in the system.',
                count: students.length,
              ),
              const SizedBox(height: 16),
              if (students.isEmpty)
                const Center(child: Text('No students registered yet.'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final student = students[index];
                      final deptName = departments
                              ?.where((d) => d.id == student.departmentId)
                              .firstOrNull
                              ?.name ??
                          '—';
                      return AppCard(
                        child: ListTile(
                          title: Text(student.name),
                          subtitle: Text(
                            '${student.studentId} • ${student.email}',
                          ),
                          trailing: Text(
                            deptName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class AdminLecturersDetailScreen extends ConsumerWidget {
  const AdminLecturersDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturersAsync = ref.watch(_lecturersProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: lecturersAsync.when(
        data: (lecturers) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailHeader(
                title: 'Lecturers',
                subtitle: 'All registered lecturers in the system.',
                count: lecturers.length,
              ),
              const SizedBox(height: 16),
              if (lecturers.isEmpty)
                const Center(child: Text('No lecturers registered yet.'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: lecturers.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final lecturer = lecturers[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(lecturer.name),
                          subtitle: Text(
                            '${lecturer.lecturerId} • ${lecturer.email}',
                          ),
                          trailing: Text(
                            '${lecturer.courseIds.length} courses',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class AdminCoursesDetailScreen extends ConsumerWidget {
  const AdminCoursesDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(_coursesProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: coursesAsync.when(
        data: (courses) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailHeader(
                title: 'Courses',
                subtitle: 'Course catalog and department coverage.',
                count: courses.length,
              ),
              const SizedBox(height: 16),
              if (courses.isEmpty)
                const Center(child: Text('No courses available.'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: courses.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final course = courses[index];
                      return AppCard(
                        child: ListTile(
                          title: Text(course.name),
                          subtitle: Text(
                            course.courseCode != null
                                ? '${course.courseCode} • ${course.allowsAllDepartments ? 'All departments' : '${course.allowedDepartmentIds.length} departments'}'
                                : course.allowsAllDepartments
                                ? 'All departments'
                                : '${course.allowedDepartmentIds.length} departments',
                          ),
                          trailing: Text(
                            course.createdByName ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class AdminSessionsDetailScreen extends ConsumerStatefulWidget {
  const AdminSessionsDetailScreen({super.key});

  @override
  ConsumerState<AdminSessionsDetailScreen> createState() =>
      _AdminSessionsDetailScreenState();
}

class _AdminSessionsDetailScreenState
    extends ConsumerState<AdminSessionsDetailScreen> {
  String? selectedDepartmentId;
  String? selectedLecturerId;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(_departmentsProvider);
    final lecturersAsync = ref.watch(_lecturersProvider);
    final coursesAsync = ref.watch(_coursesProvider);
    final sessionsAsync = ref.watch(_sessionsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailHeader(
            title: 'Sessions',
            subtitle: 'Filter attendance sessions by department and lecturer.',
            count: sessionsAsync.maybeWhen(
              data: (sessions) => sessions.length,
              orElse: () => 0,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filter sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                departmentsAsync.when(
                  data: (departments) {
                    final lecturers = lecturersAsync.maybeWhen(
                      data: (data) => data,
                      orElse: () => <Lecturer>[],
                    );
                    final filteredLecturers = selectedDepartmentId == null
                        ? <Lecturer>[]
                        : lecturers
                              .where(
                                (lecturer) =>
                                    lecturer.departmentId ==
                                    selectedDepartmentId,
                              )
                              .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedDepartmentId,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                          items: departments
                              .map(
                                (department) => DropdownMenuItem(
                                  value: department.id,
                                  child: Text(department.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDepartmentId = value;
                              selectedLecturerId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedLecturerId,
                          decoration: const InputDecoration(
                            labelText: 'Lecturer',
                          ),
                          items: filteredLecturers
                              .map(
                                (lecturer) => DropdownMenuItem(
                                  value: lecturer.id,
                                  child: Text(lecturer.name),
                                ),
                              )
                              .toList(),
                          onChanged: filteredLecturers.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedLecturerId = value;
                                  });
                                },
                          hint: const Text('Choose a department first'),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (selectedDepartmentId != null)
                              Chip(
                                label: Text(
                                  'Department: ${departments.firstWhere((dept) => dept.id == selectedDepartmentId).name}',
                                ),
                              ),
                            if (selectedLecturerId != null)
                              Chip(
                                label: Text(
                                  'Lecturer: ${filteredLecturers.firstWhere((lecturer) => lecturer.id == selectedLecturerId).name}',
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('Failed to load filters: $e')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DangerButton(
            label: 'Clear all sessions',
            icon: Icons.delete_sweep_outlined,
            confirmTitle: 'Clear all sessions?',
            confirmBody:
                'This will permanently delete every attendance session and cannot be undone.',
            collection: AppConstants.sessionsCollection,
            successMsg: 'All sessions cleared.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                final lecturers = lecturersAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <Lecturer>[],
                );
                final departments = departmentsAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <Department>[],
                );
                final courses = coursesAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <Course>[],
                );
                final visibleSessions = _filteredSessions(
                  sessions,
                  lecturers,
                  selectedDepartmentId,
                  selectedLecturerId,
                );

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: visibleSessions.isEmpty
                      ? Center(
                          child: Text(
                            selectedDepartmentId == null
                                ? 'Select a department to begin filtering sessions.'
                                : 'No sessions match the selected lecturer.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          key: ValueKey(
                            '${selectedDepartmentId ?? 'all'}-${selectedLecturerId ?? 'all'}',
                          ),
                          itemCount: visibleSessions.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final session = visibleSessions[index];
                            final lecturer = lecturers.firstWhere(
                              (item) => item.id == session.lecturerId,
                              orElse: () => LecturerModel(
                                id: session.lecturerId,
                                name: 'Unknown lecturer',
                                lecturerId: session.lecturerId,
                                email: '',
                                departmentId: '',
                                courseIds: [],
                              ),
                            );
                            final department = departments.firstWhere(
                              (item) => item.id == lecturer.departmentId,
                              orElse: () => const DepartmentModel(
                                id: '',
                                name: 'Unknown department',
                              ),
                            );
                            final course = courses
                                .where((c) => c.id == session.courseId)
                                .firstOrNull;
                            final courseLabel = course == null
                                ? session.courseId
                                : (course.courseCode != null &&
                                        course.courseCode!.isNotEmpty
                                    ? '${course.courseCode} — ${course.name}'
                                    : course.name);

                            return AppCard(
                              child: ListTile(
                                isThreeLine: true,
                                title: Text(courseLabel),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lecturer: ${lecturer.name}'),
                                    Text('Department: ${department.name}'),
                                    Text(
                                      _formatDateRange(
                                        session.startTime,
                                        session.endTime,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(
                                    session.isActive ? 'Active' : 'Closed',
                                  ),
                                  backgroundColor: session.isActive
                                      ? Colors.green.withValues(alpha: 0.14)
                                      : Colors.grey.withValues(alpha: 0.18),
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  List<AttendanceSession> _filteredSessions(
    List<AttendanceSession> sessions,
    List<Lecturer> lecturers,
    String? departmentId,
    String? lecturerId,
  ) {
    final matchingLecturerIds = <String>{};

    if (lecturerId != null) {
      matchingLecturerIds.add(lecturerId);
    } else if (departmentId != null) {
      matchingLecturerIds.addAll(
        lecturers
            .where((lecturer) => lecturer.departmentId == departmentId)
            .map((lecturer) => lecturer.id),
      );
    }

    if (matchingLecturerIds.isEmpty && departmentId != null) {
      return [];
    }

    return sessions.where((session) {
      if (matchingLecturerIds.isNotEmpty) {
        return matchingLecturerIds.contains(session.lecturerId);
      }
      return true;
    }).toList();
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startLabel =
        '${start.month}/${start.day} ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}';
    final endLabel =
        '${end.month}/${end.day} ${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
    return '$startLabel – $endLabel';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class AdminRecordsDetailScreen extends ConsumerWidget {
  const AdminRecordsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(_recordsProvider);
    final allUsers = ref.watch(_allUsersProvider).asData?.value;
    final courses = ref.watch(_coursesProvider).asData?.value;
    final sessions = ref.watch(_sessionsProvider).asData?.value;

    return Padding(
      padding: AppTheme.screenPadding,
      child: recordsAsync.when(
        data: (records) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailHeader(
                title: 'Attendance records',
                subtitle: 'Detailed attendance events and statuses.',
                count: records.length,
              ),
              const SizedBox(height: 16),
              _DangerButton(
                label: 'Clear all records',
                icon: Icons.playlist_remove_outlined,
                confirmTitle: 'Clear all records?',
                confirmBody:
                    'This will permanently delete every attendance record. '
                    'This action cannot be undone.',
                collection: AppConstants.recordsCollection,
                successMsg: 'All attendance records cleared.',
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                const Center(child: Text('No attendance records yet.'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final record = records[index];

                      final course = courses
                          ?.where((c) => c.id == record.courseId)
                          .firstOrNull;
                      final session = sessions
                          ?.where((s) => s.id == record.sessionId)
                          .firstOrNull;
                      final courseLabel = course != null
                          ? (course.courseCode?.isNotEmpty == true
                              ? '${course.courseCode} — ${course.name}'
                              : course.name)
                          : session != null
                              ? 'Session · ${session.startTime.month}/${session.startTime.day} ${_twoDigits(session.startTime.hour)}:${_twoDigits(session.startTime.minute)}'
                              : 'Attendance record';

                      final studentName = allUsers
                              ?.where((u) => u.id == record.studentId)
                              .firstOrNull
                              ?.name ??
                          'Unknown student';

                      return AppCard(
                        child: ListTile(
                          title: Text(courseLabel),
                          subtitle: Text(
                            '$studentName • ${record.status.name.toUpperCase()}',
                          ),
                          trailing: Text(
                            '${record.timestamp.month}/${record.timestamp.day} ${_twoDigits(record.timestamp.hour)}:${_twoDigits(record.timestamp.minute)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class AdminSecurityLogsScreen extends ConsumerWidget {
  const AdminSecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_securityLogsProvider);
    final allUsers = ref.watch(_allUsersProvider).asData?.value;
    final sessions = ref.watch(_sessionsProvider).asData?.value;
    final courses = ref.watch(_coursesProvider).asData?.value;

    return Padding(
      padding: AppTheme.screenPadding,
      child: logsAsync.when(
        data: (logs) {
          final chartData = _groupLogsByDay(logs);
          final errorLogs = logs
              .where(
                (log) =>
                    log.action.toLowerCase().contains('error') ||
                    log.details.toLowerCase().contains('error'),
              )
              .toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailHeader(
                        title: 'Security logs',
                        subtitle:
                            'Track system events, error messages, and incident details clearly.',
                        count: logs.length,
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Activity trends',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text('${logs.length} total events'),
                                ),
                                Chip(
                                  label: Text(
                                    '${errorLogs.length} error events',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              child: _SecurityLogChart(
                                key: ValueKey(logs.length),
                                data: chartData,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (logs.isEmpty)
                        const Center(
                          child: Text('No security log activity yet.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          key: ValueKey('${logs.length}-${errorLogs.length}'),
                          itemCount: logs.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final log = logs[index];

                            // Resolve user name — distinguish loading vs not-found
                            final String userName;
                            if (allUsers == null) {
                              userName = '…';
                            } else {
                              userName = allUsers
                                      .where((u) => u.id == log.userId)
                                      .firstOrNull
                                      ?.name ??
                                  'Unknown user';
                            }

                            // Resolve session — distinguish loading vs deleted
                            String sessionLabel = 'N/A';
                            if (log.sessionId != null &&
                                log.sessionId!.isNotEmpty) {
                              if (sessions == null) {
                                sessionLabel = '…';
                              } else {
                                final session = sessions
                                    .where((s) => s.id == log.sessionId)
                                    .firstOrNull;
                                if (session != null) {
                                  final course = courses
                                      ?.where((c) => c.id == session.courseId)
                                      .firstOrNull;
                                  final courseLabel = course != null
                                      ? (course.courseCode?.isNotEmpty == true
                                          ? course.courseCode!
                                          : course.name)
                                      : null;
                                  sessionLabel = courseLabel != null
                                      ? '$courseLabel · ${_formatTimestamp(session.startTime)}'
                                      : _formatTimestamp(session.startTime);
                                } else {
                                  sessionLabel = 'Session (deleted)';
                                }
                              }
                            }

                            // Human-readable action title from snake_case
                            final actionTitle = _formatAction(log.action);
                            // Show detail text only when it adds info beyond the action name
                            final detailsText =
                                log.details.isNotEmpty &&
                                        log.details != log.action
                                    ? log.details
                                    : null;

                            return AppCard(
                              child: ListTile(
                                isThreeLine: true,
                                title: Text(
                                  actionTitle.isNotEmpty
                                      ? actionTitle
                                      : 'Security event',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    if (detailsText != null) ...[
                                      Text(detailsText),
                                      const SizedBox(height: 8),
                                    ],
                                    Text(
                                      'User: $userName • Session: $sessionLabel',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 80,
                                  child: Text(
                                    _formatTimestamp(log.timestamp),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      _DangerButton(
                        label: 'Clear security logs',
                        icon: Icons.shield_outlined,
                        confirmTitle: 'Clear security logs?',
                        confirmBody:
                            'This will permanently delete all security logs and cannot be undone.',
                        collection: AppConstants.securityLogsCollection,
                        successMsg: 'Security logs cleared.',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    return '${value.month}/${value.day} ${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatAction(String action) {
    return action
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<_SecurityLogPoint> _groupLogsByDay(List<SecurityLog> logs) {
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final counts = <DateTime, int>{};

    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        cutoff.year,
        cutoff.month,
        cutoff.day,
      ).add(Duration(days: i));
      counts[day] = 0;
    }

    for (final log in logs) {
      final day = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      if (counts.containsKey(day)) {
        counts[day] = counts[day]! + 1;
      }
    }

    return counts.entries
        .map((entry) => _SecurityLogPoint(entry.key, entry.value))
        .toList();
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Chip(
                label: Text('$count items'),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
              ),
              Chip(
                label: const Text('Live sync from Firestore'),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityLogPoint {
  const _SecurityLogPoint(this.date, this.count);

  final DateTime date;
  final int count;
}

class _SecurityLogChart extends StatelessWidget {
  const _SecurityLogChart({super.key, required this.data});

  final List<_SecurityLogPoint> data;

  @override
  Widget build(BuildContext context) {
    final maxCount = data.map((point) => point.count).fold<int>(0, max);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((point) {
              final heightFactor = maxCount == 0 ? 0.1 : point.count / maxCount;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      height: max(14, heightFactor * 140),
                      width: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${point.date.month}/${point.date.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.count.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

final _allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

final _studentsProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchStudents();
});

final _lecturersProvider = StreamProvider<List<Lecturer>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchLecturers();
});

final _coursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _departmentsProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});

final _sessionsProvider = StreamProvider<List<AttendanceSession>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.sessionsCollection)
      .orderBy('startTime', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => AttendanceSessionModel.fromFirestore(doc))
            .toList(),
      );
});

final _recordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.recordsCollection)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => AttendanceRecordModel.fromFirestore(doc))
            .toList(),
      );
});

final _securityLogsProvider = StreamProvider<List<SecurityLog>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.securityLogsCollection)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) {
        return snap.docs.map((doc) {
          final data = doc.data();
          return SecurityLog(
            id: doc.id,
            userId: data['userId'] as String? ?? '',
            action: data['action'] as String? ?? '',
            details: data['details'] as String? ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            sessionId: data['sessionId'] as String?,
          );
        }).toList();
      });
});

class _DangerButton extends StatefulWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.confirmTitle,
    required this.confirmBody,
    required this.collection,
    required this.successMsg,
  });

  final String label;
  final IconData icon;
  final String confirmTitle;
  final String confirmBody;
  final String collection;
  final String successMsg;

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
  bool _loading = false;

  Future<void> _deleteAllDocs() async {
    final db = FirebaseFirestore.instance;
    const batchSize = 400;
    while (true) {
      final snap = await db.collection(widget.collection).limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
  }

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.confirmTitle),
        content: Text(widget.confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _deleteAllDocs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.successMsg), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: BorderSide(color: Colors.red.shade300),
      ),
      onPressed: _loading ? null : _confirm,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : Icon(widget.icon),
      label: Text(widget.label),
    );
  }
}
