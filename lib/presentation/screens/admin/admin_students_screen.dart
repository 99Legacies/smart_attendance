import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_loading.dart';

class AdminStudentsScreen extends ConsumerWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_studentsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }
          return ListView.separated(
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
                    onPressed: () => _resetDevice(ref, s),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const ApLoadingList(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _resetDevice(WidgetRef ref, Student student) async {
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

final _studentsProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchStudents();
});
