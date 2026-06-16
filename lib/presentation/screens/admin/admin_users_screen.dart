import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/utils/snackbar_utils.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String? _departmentFilter;
  UserRole? _roleFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users.where((user) {
      final matchesDepartment =
          _departmentFilter == null || user.department == _departmentFilter;
      final matchesRole = _roleFilter == null || user.role == _roleFilter;
      final matchesSearch =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      return matchesDepartment && matchesRole && matchesSearch;
    }).toList();
  }

  Future<void> _changeRole(AppUser user) async {
    // Allow toggling between student and lecturer only
    final UserRole newRole;
    if (user.role == UserRole.student) {
      newRole = UserRole.lecturer;
    } else if (user.role == UserRole.lecturer) {
      newRole = UserRole.student;
    } else {
      // Admin — don't allow toggle via this UI
      SnackbarUtils.showError(context, 'Admin roles cannot be changed here.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change role'),
        content: Text('Change ${user.name}\'s role to ${newRole.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(userRepositoryProvider)
          .updateUserRole(uid: user.id, role: newRole);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        '${user.name} is now ${newRole.label}',
      );
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Permanently delete ${user.name} (${user.email})? '
          'This removes their profile from the system.',
        ),
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

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(userRepositoryProvider).deleteUser(user.id);
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '${user.name} deleted');
    } on AppException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.message);
    }
  }

  void _showUserDetails(AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            _detailRow(ctx, 'Email', user.email),
            _detailRow(ctx, 'Department', user.department),
            _detailRow(ctx, 'Role', user.role.label),
            _detailRow(
              ctx,
              'Joined',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final departmentsAsync = ref.watch(_departmentsProvider);

    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Fix overflow: use Column instead of Row so dropdowns stack vertically
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              departmentsAsync.when(
                data: (departments) => DropdownButtonFormField<String?>(
                  initialValue: _departmentFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All departments'),
                    ),
                    ...departments.map(
                      (d) => DropdownMenuItem<String?>(
                        value: d.name,
                        child: Text(
                          d.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _departmentFilter = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole?>(
                initialValue: _roleFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<UserRole?>(
                    value: null,
                    child: Text('All roles'),
                  ),
                  // Fix: student and lecturer only, not admin
                  ...[UserRole.student, UserRole.lecturer].map(
                    (r) => DropdownMenuItem<UserRole?>(
                      value: r,
                      child: Text(r.label),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _filterUsers(users);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          users.isEmpty
                              ? 'No users registered yet'
                              : 'No users match your filters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(usersProvider);
                    await ref.read(usersProvider.future);
                  },
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final user = filtered[i];
                      return AppCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(user.name),
                          subtitle: Text('${user.email}\n${user.department}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'view':
                                  _showUserDetails(user);
                                case 'role':
                                  _changeRole(user);
                                case 'delete':
                                  _deleteUser(user);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: ListTile(
                                  leading: Icon(Icons.visibility_outlined),
                                  title: Text('View details'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'role',
                                child: ListTile(
                                  leading: Icon(Icons.swap_horiz),
                                  title: Text('Change role'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showUserDetails(user),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load users: $e'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(usersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final usersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

final _departmentsProvider = StreamProvider<List<Department>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchDepartments();
});
