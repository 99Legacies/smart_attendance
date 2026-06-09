import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/utils/validators.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/core/widgets/firestore_department_dropdown.dart';
import 'package:smart_attendance/domain/entities/course_proposal.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class LecturerProposeCourseScreen extends ConsumerStatefulWidget {
  const LecturerProposeCourseScreen({
    super.key,
    required this.lecturerId,
    required this.lecturerName,
  });

  final String lecturerId;
  final String lecturerName;

  @override
  ConsumerState<LecturerProposeCourseScreen> createState() =>
      _LecturerProposeCourseScreenState();
}

class _LecturerProposeCourseScreenState
    extends ConsumerState<LecturerProposeCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _departmentId;
  bool _submitting = false;

  @override
  void dispose() {
    _courseIdController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departmentId == null) {
      SnackbarUtils.showError(context, 'Select a department');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(courseProposalRepositoryProvider).submitProposal(
            proposedCourseId: _courseIdController.text,
            name: _nameController.text,
            description: _descriptionController.text,
            departmentId: _departmentId!,
            lecturerId: widget.lecturerId,
            lecturerName: widget.lecturerName,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        'Course submitted for admin review',
      );
      _courseIdController.clear();
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _departmentId = null);
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposalsAsync =
        ref.watch(_lecturerProposalsProvider(widget.lecturerId));

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Propose a new course',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Submit course details for admin approval. Once approved, the course is added to the catalog.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _courseIdController,
                    decoration: const InputDecoration(
                      labelText: 'Course ID',
                      hintText: 'e.g. CS101',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      final base = Validators.requiredField(v, 'Course ID');
                      if (base != null) return base;
                      if (v!.trim().length < 2) {
                        return 'Course ID must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (v) => Validators.requiredField(v, 'Course name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        Validators.requiredField(v, 'Description'),
                  ),
                  const SizedBox(height: 12),
                  FirestoreDepartmentDropdown(
                    value: _departmentId,
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit for review'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'My proposals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          proposalsAsync.when(
            data: (proposals) {
              if (proposals.isEmpty) {
                return const Text('No proposals yet.');
              }
              return Column(
                children: proposals
                    .map(
                      (p) => AppCard(
                        child: ListTile(
                          title: Text('${p.proposedCourseId} — ${p.name}'),
                          subtitle: Text(
                            '${p.status.name.toUpperCase()}'
                            '${p.adminFeedback != null ? '\n${p.adminFeedback}' : ''}',
                          ),
                          isThreeLine: p.adminFeedback != null,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

final _lecturerProposalsProvider =
    StreamProvider.family<List<CourseProposal>, String>((ref, lecturerId) {
  return ref
      .watch(courseProposalRepositoryProvider)
      .watchProposalsForLecturer(lecturerId);
});
