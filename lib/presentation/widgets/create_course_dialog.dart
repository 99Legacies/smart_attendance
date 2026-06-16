import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/core/widgets/firestore_department_dropdown.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

/// Creates a course immediately (admin) with full department list and creator audit.
Future<void> showAdminCreateCourseDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(authStateProvider).value;
  if (user == null) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _CreateCourseDialog(
      createdBy: user.uid,
      createdByName: user.name ?? 'Admin',
      createdByRole: UserRole.admin.name,
      submitLabel: 'Create course',
      onSubmit: (data) => ref.read(catalogRepositoryProvider).createCourse(
            name: data.name,
            departmentId: data.departmentId,
            courseCode: data.courseCode,
            description: data.description,
            createdBy: data.createdBy,
            createdByName: data.createdByName,
            createdByRole: data.createdByRole,
          ),
    ),
  );
}

class _CourseFormData {
  const _CourseFormData({
    required this.name,
    required this.departmentId,
    required this.courseCode,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
  });

  final String name;
  final String departmentId;
  final String courseCode;
  final String description;
  final String createdBy;
  final String createdByName;
  final String createdByRole;
}

class _CreateCourseDialog extends StatefulWidget {
  const _CreateCourseDialog({
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final String submitLabel;
  final Future<void> Function(_CourseFormData data) onSubmit;

  @override
  State<_CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _departmentId;
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _departmentId == null) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _CourseFormData(
          name: _nameController.text.trim(),
          departmentId: _departmentId!,
          courseCode: _codeController.text.trim().toUpperCase(),
          description: _descriptionController.text.trim(),
          createdBy: widget.createdBy,
          createdByName: widget.createdByName,
          createdByRole: widget.createdByRole,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      SnackbarUtils.showSuccess(context, 'Course created');
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New course'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course ID',
                  hintText: 'e.g. CS101',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  final base = Validators.requiredField(v, 'Course ID');
                  if (base != null) return base;
                  if (v!.trim().length < 2) {
                    return 'At least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course name'),
                validator: (v) => Validators.requiredField(v, 'Course name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => Validators.requiredField(v, 'Description'),
              ),
              const SizedBox(height: 12),
              FirestoreDepartmentDropdown(
                value: _departmentId,
                onChanged: (v) => setState(() => _departmentId = v),
                returnId: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Creator: ${widget.createdByName} (${widget.createdByRole})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}
