import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/core/widgets/preset_department_dropdown.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

/// Profile view/edit dialog backed by the `users` collection.
class UserProfileEditor extends ConsumerStatefulWidget {
  const UserProfileEditor({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  ConsumerState<UserProfileEditor> createState() => _UserProfileEditorState();
}

class _UserProfileEditorState extends ConsumerState<UserProfileEditor> {
  late final TextEditingController _nameController;
  late String? _department;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _department = widget.user.department;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _department == null) {
      SnackbarUtils.showError(context, 'Name and department are required');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateUserProfile(
            uid: widget.user.id,
            name: name,
            department: _department!,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Profile updated');
      Navigator.pop(context, true);
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
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => Validators.requiredField(v, 'Full name'),
            ),
            const SizedBox(height: 16),
            PresetDepartmentDropdown(
              value: _department,
              onChanged: (v) => setState(() => _department = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${widget.user.email}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(authUser.uid);
});
