import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerCoursesScreen extends ConsumerWidget {
  const LecturerCoursesScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturerAsync = ref.watch(_lecturerProvider(lecturerId));
    final coursesAsync = ref.watch(_allCoursesProvider);

    return lecturerAsync.when(
      data: (lecturer) {
        if (lecturer == null) {
          return const Center(child: Text('Lecturer profile not found.'));
        }
        return coursesAsync.when(
          data: (allCourses) => _CourseList(
            lecturer: lecturer,
            allCourses: allCourses,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _CourseList extends ConsumerStatefulWidget {
  const _CourseList({required this.lecturer, required this.allCourses});

  final Lecturer lecturer;
  final List<Course> allCourses;

  @override
  ConsumerState<_CourseList> createState() => _CourseListState();
}

class _CourseListState extends ConsumerState<_CourseList> {
  final _searchController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter courses to lecturer's department only
  List<Course> get _departmentCourses {
    final deptId = widget.lecturer.departmentId;
    if (deptId.isEmpty) return widget.allCourses;
    return widget.allCourses
        .where((c) => c.allowsDepartment(deptId))
        .toList();
  }

  List<Course> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _departmentCourses;
    return _departmentCourses
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _toggle(Course course, bool enrolled) async {
    setState(() => _saving = true);
    try {
      final current = List<String>.from(widget.lecturer.courseIds);
      if (enrolled) {
        current.remove(course.id);
      } else {
        if (!current.contains(course.id)) current.add(course.id);
      }

      await ref.read(catalogRepositoryProvider).updateLecturer(
            _lecturerWithCourses(widget.lecturer, current),
          );

      // Invalidate so UI re-reads updated lecturer
      ref.invalidate(_lecturerProvider(widget.lecturer.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enrolled
                  ? '${course.name} removed from your courses'
                  : '${course.name} added to your courses',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrolled = widget.lecturer.courseIds;
    final filtered = _filtered;
    final myCourses = _departmentCourses
        .where((c) => enrolled.contains(c.id))
        .toList();

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // My courses summary
          if (myCourses.isNotEmpty) ...[
            Text(
              'My Courses (${myCourses.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: myCourses
                  .map(
                    (c) => Chip(
                      label: Text(c.name),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _saving ? null : () => _toggle(c, true),
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 24),
          ],

          // Search
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search courses in your department',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Department Courses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 6),
              const Tooltip(
                message: 'Showing courses for your department only',
                child: Icon(Icons.info_outline, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Course list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No courses found for your department.'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final course = filtered[i];
                      final isEnrolled = enrolled.contains(course.id);
                      return AppCard(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEnrolled
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              isEnrolled ? Icons.check : Icons.school_outlined,
                              color: isEnrolled
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          title: Text(course.name),
                          subtitle: Text(
                            course.courseCode ?? 'ID: ${course.id}',
                          ),
                          trailing: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : FilledButton.tonal(
                                  onPressed: () => _toggle(course, isEnrolled),
                                  style: isEnrolled
                                      ? FilledButton.styleFrom(
                                          backgroundColor: Colors.red.shade50,
                                          foregroundColor: Colors.red,
                                        )
                                      : null,
                                  child: Text(isEnrolled ? 'Remove' : 'Add'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Lecturer _lecturerWithCourses(Lecturer l, List<String> courseIds) {
  return Lecturer(
    id: l.id,
    name: l.name,
    lecturerId: l.lecturerId,
    email: l.email,
    departmentId: l.departmentId,
    courseIds: courseIds,
  );
}

final _lecturerProvider = FutureProvider.family<Lecturer?, String>((ref, uid) {
  return ref.read(catalogRepositoryProvider).getLecturer(uid).timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
});

final _allCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});
