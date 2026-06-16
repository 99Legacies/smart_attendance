import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_loading.dart';

// Holds the data we need after both async fetches complete.
class _CourseData {
  const _CourseData({
    required this.student,
    required this.enrolled,
    required this.available,
  });
  final Student? student;
  final List<Course> enrolled;
  final List<Course> available;
}

// Load the student profile once, then stream courses live from Firestore via
// watchCourses() so courses added by admin appear without restarting the app.
final _courseDataProvider =
    StreamProvider.autoDispose.family<_CourseData, String>((ref, studentUid) async* {
  final catalog = ref.read(catalogRepositoryProvider);

  final student = await catalog.getStudent(studentUid).timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
  final enrolledIds = (student?.courseIds ?? <String>[]).cast<String>();
  final departmentId =
      (student?.departmentId ?? '').trim().isEmpty ? null : student!.departmentId;

  await for (final deptCourses in catalog.watchCourses(departmentId: departmentId)) {
    final enrolled = deptCourses.where((c) => enrolledIds.contains(c.id)).toList();
    final available = deptCourses.where((c) => !enrolledIds.contains(c.id)).toList();
    yield _CourseData(student: student, enrolled: enrolled, available: available);
  }
});

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key, required this.studentUid});

  final String studentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollRepo = ref.watch(enrollmentRepositoryProvider);
    final dataAsync = ref.watch(_courseDataProvider(studentUid));

    return dataAsync.when(
      loading: () => const ApLoadingList(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final departmentId = data.student?.departmentId ?? '';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Text(
              'Enrolled Courses',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (data.enrolled.isEmpty)
              _emptyCard(context, 'No enrolled courses yet.')
            else
              ...data.enrolled.map((c) => _courseCard(context, c, enrolled: true)),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Available Courses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                if (departmentId.isNotEmpty)
                  const Tooltip(
                    message: 'Showing courses for your department only',
                    child: Icon(Icons.info_outline, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.available.isEmpty)
              _emptyCard(context, 'No available courses for your department.')
            else
              ...data.available.map(
                (c) => _courseCard(
                  context,
                  c,
                  enrolled: false,
                  onRegister: () async {
                    try {
                      await enrollRepo.enroll(
                        studentId: studentUid,
                        courseId: c.id,
                      );
                      // Invalidate so the list refreshes after enrollment.
                      ref.invalidate(_courseDataProvider(studentUid));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registered — will sync when online'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to register: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _emptyCard(BuildContext context, String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }

  Widget _courseCard(
    BuildContext context,
    Course c, {
    required bool enrolled,
    VoidCallback? onRegister,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: enrolled
                  ? Colors.green.withValues(alpha: 0.16)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                enrolled ? Icons.check : Icons.school,
                color: enrolled
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if ((c.courseCode ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      c.courseCode!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            enrolled
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: onRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
