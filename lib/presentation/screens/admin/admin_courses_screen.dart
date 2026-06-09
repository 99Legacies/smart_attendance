import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/create_course_dialog.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  String? _selectedDepartmentId; // null = show all departments

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(_coursesProvider);
    final departmentsAsync = ref.watch(_departmentsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        children: [
          // Top row: department filter + add button
          Row(
            children: [
              Expanded(
                child: departmentsAsync.when(
                  data: (deps) => DropdownButtonFormField<String?>(
                    value: _selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by department',
                      prefixIcon: Icon(Icons.filter_list),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All departments'),
                      ),
                      ...deps.map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDepartmentId = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => showAdminCreateCourseDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                // Apply department filter
                final filtered = _selectedDepartmentId == null
                    ? courses
                    : courses
                        .where(
                          (c) => c.allowsDepartment(_selectedDepartmentId!),
                        )
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedDepartmentId == null
                          ? 'No courses yet.'
                          : 'No courses for this department.',
                    ),
                  );
                }

                return departmentsAsync.when(
                  data: (deps) => ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final deptName = c.allowsAllDepartments
                          ? 'All departments'
                          : _deptName(deps, c.departmentId);
                      return AppCard(
                        child: ListTile(
                          title: Text(
                            c.courseCode != null
                                ? '${c.courseCode} — ${c.name}'
                                : c.name,
                          ),
                          subtitle: Text(
                            'Dept: $deptName'
                            '${c.createdByName != null ? '\nCreated by ${c.createdByName} (${c.createdByRole})' : ''}',
                          ),
                          isThreeLine: c.createdByName != null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, ref, c),
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course'),
        content: Text('Delete "${course.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(catalogRepositoryProvider).deleteCourse(course.id);
    }
  }

  String _deptName(List<Department> deps, String id) {
    for (final d in deps) {
      if (d.id == id) return d.name;
    }
    return id;
  }
}

final _coursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});

final _departmentsProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});
