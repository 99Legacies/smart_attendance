import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/course_proposal.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class AdminPendingCoursesScreen extends ConsumerWidget {
  const AdminPendingCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(_pendingProposalsProvider);

    return proposalsAsync.when(
      data: (proposals) {
        if (proposals.isEmpty) {
          return const Center(
            child: Text('No pending course proposals.'),
          );
        }
        return ListView.separated(
          padding: AppTheme.screenPadding,
          itemCount: proposals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ProposalReviewCard(proposal: proposals[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ProposalReviewCard extends ConsumerStatefulWidget {
  const _ProposalReviewCard({required this.proposal});

  final CourseProposal proposal;

  @override
  ConsumerState<_ProposalReviewCard> createState() =>
      _ProposalReviewCardState();
}

class _ProposalReviewCardState extends ConsumerState<_ProposalReviewCard> {
  final _feedbackController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final adminId = ref.read(authStateProvider).value?.uid;
    if (adminId == null) return;

    setState(() => _processing = true);
    try {
      await ref.read(courseProposalRepositoryProvider).approveProposal(
            proposalId: widget.proposal.id,
            adminId: adminId,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Course approved and published');
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    if (_feedbackController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Provide feedback when rejecting');
      return;
    }
    final adminId = ref.read(authStateProvider).value?.uid;
    if (adminId == null) return;

    setState(() => _processing = true);
    try {
      await ref.read(courseProposalRepositoryProvider).rejectProposal(
            proposalId: widget.proposal.id,
            adminId: adminId,
            feedback: _feedbackController.text,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Proposal rejected');
      _feedbackController.clear();
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proposal;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.proposedCourseId} — ${p.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Lecturer: ${p.lecturerName}'),
            const SizedBox(height: 8),
            Text(p.description),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (required for rejection)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing ? null : _reject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _processing ? null : _approve,
                    child: _processing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _pendingProposalsProvider = StreamProvider<List<CourseProposal>>((ref) {
  return ref.watch(courseProposalRepositoryProvider).watchPendingProposals();
});
