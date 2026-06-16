import 'package:flutter/material.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';

class ApAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ApAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.userName,
    this.role,
    this.avatarUrl,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final String? userName;
  final UserRole? role;
  final String? avatarUrl;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).appBarTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: isDark ? 0.22 : 0.88),
      foregroundColor: theme.foregroundColor,
      elevation: 0,
      scrolledUnderElevation: theme.scrolledUnderElevation,
      iconTheme: theme.iconTheme,
      actionsIconTheme: theme.actionsIconTheme,
      systemOverlayStyle: theme.systemOverlayStyle,
      title: userName != null
          ? Row(
              children: [
                _Avatar(name: userName!, imageUrl: avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: theme.titleTextStyle!,
                        child: title,
                      ),
                      if (role != null) ...[
                        const SizedBox(height: 2),
                        _RoleBadge(role: role!, isDark: isDark),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : title,
      actions: actions,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isDark});

  final UserRole role;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.admin => AppTheme.primary,
      UserRole.lecturer => const Color(0xFF7C3AED),
      UserRole.student => AppTheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

typedef AppAppBar = ApAppBar;
