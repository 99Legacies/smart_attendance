import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_loading.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String? _selectedCourseId;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = _selectedCourseId == null
        ? ref.watch(_allStudentsProvider)
        : ref.watch(_studentsByCourseProvider(_selectedCourseId!));
    final coursesAsync = ref.watch(_adminCoursesProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          coursesAsync.when(
            data: (courses) => DropdownButtonFormField<String?>(
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Filter by Course',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Courses'),
                ),
                ...courses.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(
                      c.courseCode != null
                          ? '${c.courseCode} — ${c.name}'
                          : c.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or student ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: studentsAsync.when(
              data: (all) {
                final students = _search.isEmpty
                    ? all
                    : all
                        .where(
                          (s) =>
                              s.name.toLowerCase().contains(_search) ||
                              s.studentId.toLowerCase().contains(_search),
                        )
                        .toList();

                if (all.isEmpty && _selectedCourseId != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No students registered for this course.',
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedCourseId = null),
                          child: const Text('Clear Filter'),
                        ),
                      ],
                    ),
                  );
                }

                if (students.isEmpty) {
                  return const Center(child: Text('No matching students.'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${students.length} student${students.length == 1 ? '' : 's'} found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = students[i];
                          return AppCard(
                            child: ListTile(
                              title: Text(s.name),
                              subtitle: Text('${s.studentId} • ${s.email}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.phonelink_erase),
                                tooltip: 'Reset device',
                                onPressed: () => _resetDevice(s),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const ApLoadingList(),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDevice(Student student) async {
    final updated = Student(
      id: student.id,
      name: student.name,
      studentId: student.studentId,
      email: student.email,
      departmentId: student.departmentId,
      courseIds: student.courseIds,
      deviceId: null,
    );
    await ref.read(catalogRepositoryProvider).updateStudent(updated);
  }
}

final _allStudentsProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchStudents();
});

final _studentsByCourseProvider =
    StreamProvider.family<List<Student>, String>((ref, courseId) {
  return ref.watch(catalogRepositoryProvider).watchStudentsByCourse(courseId);
});

final _adminCoursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCourses();
});
