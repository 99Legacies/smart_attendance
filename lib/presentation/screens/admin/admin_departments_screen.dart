import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/data/services/department_migration_service.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class AdminDepartmentsScreen extends ConsumerStatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  ConsumerState<AdminDepartmentsScreen> createState() =>
      _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState
    extends ConsumerState<AdminDepartmentsScreen> {
  bool _migrating = false;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(_departmentsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _migrating ? null : _runMigration,
                icon: _migrating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build_outlined),
                label: const Text('Backfill IDs'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: departmentsAsync.when(
              data: (deps) {
                if (deps.isEmpty) {
                  return const Center(child: Text('No departments yet.'));
                }
                return ListView.separated(
                  itemCount: deps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = deps[i];
                    return AppCard(
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Text(
                          d.id,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(d),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runMigration() async {
    setState(() => _migrating = true);
    try {
      final report = await DepartmentMigrationService().run();
      if (!mounted) return;
      if (report.allPassed) {
        SnackbarUtils.showSuccess(
          context,
          'Backfill complete — ${report.verifyEntries.length} departments OK.',
        );
      } else {
        SnackbarUtils.showError(
          context,
          '${report.verifyFailed} department(s) failed verification. '
          'Check the debug console for details.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Migration error: $e');
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  Future<void> _confirmDelete(Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete department'),
        content: Text('Delete "${dept.name}"? This cannot be undone.'),
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
      await ref.read(catalogRepositoryProvider).deleteDepartment(dept.id);
    }
  }

  Future<void> _showDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Department'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(catalogRepositoryProvider)
                    .createDepartment(controller.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

final _departmentsProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});
