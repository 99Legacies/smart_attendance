import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/domain/entities/course.dart';

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key, required this.studentUid});

  final String studentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogRepositoryProvider);
    final enrollRepo = ref.watch(enrollmentRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        catalog.getCourses(),
        catalog.getStudent(studentUid),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = (snap.data![0] as List<Course>);
        final student = snap.data![1];
        final enrolledIds = (student?.courseIds ?? <String>[]).cast<String>();
        final studentDepartmentId = student?.departmentId ?? '';

        final enrolled = courses
            .where((c) => enrolledIds.contains(c.id))
            .toList();

        final available = courses
            .where(
              (c) =>
                  !enrolledIds.contains(c.id) &&
                  (studentDepartmentId.isEmpty ||
                      c.allowsDepartment(studentDepartmentId)),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Text(
              'Enrolled Courses',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (enrolled.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No enrolled courses yet.'),
                ),
              ),
            ...enrolled.map((c) => _courseCard(context, c, enrolled: true)),
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
                if (studentDepartmentId.isNotEmpty)
                  const Tooltip(
                    message: 'Showing courses for your department only',
                    child: Icon(Icons.info_outline, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (available.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No available courses for your department.'),
                ),
              ),
            ...available.map(
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
                  ? Colors.green.withAlpha(40)
                  : Theme.of(context).colorScheme.primary.withAlpha(30),
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
                  const SizedBox(height: 4),
                  Text(
                    c.courseCode ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
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
