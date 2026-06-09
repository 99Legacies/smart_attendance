import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/data/repositories/firebase_catalog_repository.dart';
import 'package:smart_attendance/domain/entities/department.dart';

/// Dropdown of all departments from Firestore (no user-based filtering).
class FirestoreDepartmentDropdown extends ConsumerWidget {
  const FirestoreDepartmentDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.labelText = 'Department',
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String labelText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(_allDepartmentsProvider);

    return departmentsAsync.when(
      data: (departments) {
        if (departments.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(labelText: labelText),
            child: const Text('No departments available.'),
          );
        }
        return DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: labelText),
          items: departments
              .map(
                (d) => DropdownMenuItem<String>(
                  value: d.name,
                  child: Text(d.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator:
              validator ?? (v) => v == null ? 'Select a department' : null,
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          errorText: 'Failed to load departments',
        ),
        child: Text('$e'),
      ),
    );
  }
}

final _allDepartmentsProvider = StreamProvider<List<Department>>((ref) {
  return FirebaseCatalogRepository().watchDepartments();
});
