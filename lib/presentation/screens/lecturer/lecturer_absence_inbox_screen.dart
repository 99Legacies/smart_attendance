import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/absence_request.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerAbsenceInboxScreen extends ConsumerWidget {
  const LecturerAbsenceInboxScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturerAsync = ref.watch(_lecturerProvider(lecturerId));

    return lecturerAsync.when(
      data: (lecturer) {
        if (lecturer == null) {
          return const Center(child: Text('Lecturer profile not found.'));
        }
        final requestsAsync = ref.watch(
          _pendingAbsenceProvider(lecturer.courseIds),
        );
        return requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return const Center(
                child: Text('No pending absence requests.'),
              );
            }
            return ListView.separated(
              padding: AppTheme.screenPadding,
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AbsenceRequestCard(
                request: requests[i],
                lecturerId: lecturerId,
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AbsenceRequestCard extends ConsumerStatefulWidget {
  const _AbsenceRequestCard({
    required this.request,
    required this.lecturerId,
  });

  final AbsenceRequest request;
  final String lecturerId;

  @override
  ConsumerState<_AbsenceRequestCard> createState() =>
      _AbsenceRequestCardState();
}

class _AbsenceRequestCardState extends ConsumerState<_AbsenceRequestCard> {
  final _feedbackController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _respond(AbsenceRequestStatus status) async {
    if (_feedbackController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Feedback is required');
      return;
    }
    setState(() => _processing = true);
    try {
      await ref.read(absenceRepositoryProvider).respondToRequest(
            requestId: widget.request.id,
            lecturerId: widget.lecturerId,
            status: status,
            feedback: _feedbackController.text,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        status == AbsenceRequestStatus.approved
            ? 'Request approved — attendance updated to Present'
            : 'Request rejected',
      );
      _feedbackController.clear();
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    // Fetch student profile to get their index/student ID number
    final studentAsync = ref.watch(_studentProfileProvider(r.studentId));

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name + index number
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.studentName ?? r.studentId,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                studentAsync.when(
                  data: (student) => student != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ID: ${student.studentId}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              r.courseName ?? r.courseId,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              DateFormat.yMMMd().add_jm().format(r.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(r.reason),
            if (r.fileUrl != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Attachment provided',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback to student',
                hintText: 'Explain your decision...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing
                        ? null
                        : () => _respond(AbsenceRequestStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _processing
                        ? null
                        : () => _respond(AbsenceRequestStatus.approved),
                    child: _processing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _lecturerProvider = FutureProvider.family<Lecturer?, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getLecturer(id);
});

final _studentProfileProvider =
    FutureProvider.family<Student?, String>((ref, studentId) {
  return ref.watch(catalogRepositoryProvider).getStudent(studentId);
});

final _pendingAbsenceProvider =
    StreamProvider.family<List<AbsenceRequest>, List<String>>(
        (ref, courseIds) {
  return ref
      .watch(absenceRepositoryProvider)
      .watchPendingForLecturerCourses(courseIds);
});
