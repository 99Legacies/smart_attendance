import 'package:flutter/material.dart';
import 'package:smart_attendance/core/constants/preset_departments.dart';

/// Dropdown of predefined academic departments.
class PresetDepartmentDropdown extends StatelessWidget {
  const PresetDepartmentDropdown({
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
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: labelText),
      items: PresetDepartments.all
          .map(
            (name) => DropdownMenuItem<String>(value: name, child: Text(name)),
          )
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (v) {
            if (v == null || v.isEmpty) {
              return 'Select a department';
            }
            return null;
          },
    );
  }
}
