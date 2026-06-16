import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';
import 'package:smart_attendance/presentation/screens/settings/about_screen.dart';
import 'package:smart_attendance/presentation/screens/settings/notification_settings_screen.dart';
import 'package:smart_attendance/presentation/screens/settings/preferences_screen.dart';
import 'package:smart_attendance/presentation/screens/shared/notifications_screen.dart';
import 'package:smart_attendance/presentation/widgets/report_export_sheet.dart';

/// Compact side drawer — secondary navigation only (main tabs stay on bottom bar).
class ConciseRoleDrawer extends ConsumerWidget {
  const ConciseRoleDrawer({
    super.key,
    required this.role,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.menuItems,
    this.showReportExport = false,
  });

  final UserRole role;
  final String userName;
  final String userEmail;
  final String userId;
  final List<DrawerMenuItem> menuItems;
  final bool showReportExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final surf = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final surfVar = isDark ? AppTheme.surfaceVariant : AppTheme.lightSurfaceVariant;
    final onBg = isDark ? AppTheme.onBackground : AppTheme.lightOnBackground;
    final onSurf = isDark ? AppTheme.onSurface : AppTheme.lightOnSurface;
    final border = isDark ? AppTheme.surfaceVariant : AppTheme.lightOutline;

    final currentPath = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path;
    final menuItemColors = [
      const Color(0xFF1E2456),
      const Color(0xFF064E3B),
      const Color(0xFF451A03),
      const Color(0xFF3B0764),
      const Color(0xFF450A0A),
      const Color(0xFF0C1A2E),
    ];
    final menuIconColors = [
      const Color(0xFF818CF8),
      const Color(0xFF34D399),
      const Color(0xFFFCD34D),
      const Color(0xFFC084FC),
      const Color(0xFFFCA5A5),
      const Color(0xFF60A5FA),
    ];

    Color badgeBackground;
    Color badgeBorder;
    Color badgeDot;
    Color badgeText;

    switch (role) {
      case UserRole.admin:
        badgeBackground = const Color(0xFF1E2456);
        badgeBorder = const Color(0xFF5B6BF8);
        badgeDot = const Color(0xFF5B6BF8);
        badgeText = const Color(0xFF818CF8);
        break;
      case UserRole.lecturer:
        badgeBackground = const Color(0xFF064E3B);
        badgeBorder = const Color(0xFF10B981);
        badgeDot = const Color(0xFF10B981);
        badgeText = const Color(0xFF34D399);
        break;
      case UserRole.student:
        badgeBackground = const Color(0xFF451A03);
        badgeBorder = const Color(0xFFF59E0B);
        badgeDot = const Color(0xFFF59E0B);
        badgeText = const Color(0xFFFCD34D);
        break;
    }

    bool isActiveItem(String label) {
      final slug = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      return currentPath.toLowerCase().contains(slug);
    }

    void handleMenuTap(DrawerMenuItem item) {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
      item.onTap(context);
    }

    void handleExportTap() {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
      showReportExportSheet(context, role: role, userId: userId);
    }

    return Drawer(
      width: 300,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(-20 * (1 - value), 0),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              right: BorderSide(color: border, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  decoration: BoxDecoration(
                    color: surf,
                    border: Border(
                      bottom: BorderSide(
                        color: border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final photoBase64 =
                                  snapshot.data?.data()?['photoBase64']
                                      as String?;
                              final initials = userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?';
                              Widget avatarContent;

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                avatarContent = Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.primaryGradient,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.onBackground,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (photoBase64 != null &&
                                  photoBase64.isNotEmpty) {
                                try {
                                  avatarContent = CircleAvatar(
                                    radius: 28,
                                    backgroundImage: MemoryImage(
                                      base64Decode(photoBase64),
                                    ),
                                  );
                                } catch (_) {
                                  avatarContent = Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primaryGradient,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                avatarContent = Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.primaryGradient,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(child: avatarContent),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: bg,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: onBg,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onLongPress: () {
                                    Clipboard.setData(
                                      ClipboardData(text: userEmail),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Email copied'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: onSurf,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: badgeBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: badgeDot,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        role.name.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: badgeText,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < menuItems.length;
                          index++
                        ) ...[
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              splashColor: AppTheme.primary.withValues(alpha: 0.08),
                              highlightColor: AppTheme.primary.withValues(
                                alpha: 0.04,
                              ),
                              onTap: () => handleMenuTap(menuItems[index]),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isActiveItem(menuItems[index].label)
                                      ? surfVar
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    if (isActiveItem(menuItems[index].label))
                                      Container(
                                        width: 3,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 3),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color:
                                            menuItemColors[index %
                                                menuItemColors.length],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        menuItems[index].icon,
                                        size: 18,
                                        color:
                                            menuIconColors[index %
                                                menuIconColors.length],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        menuItems[index].label,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: onBg,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: AppTheme.primary.withValues(alpha: 0.08),
                            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              AppNavigation.pushSecondary(
                                context,
                                title: 'Preferences',
                                body: const PreferencesScreen(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 13),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E2456),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.tune_outlined,
                                      size: 18,
                                      color: Color(0xFF818CF8),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Preferences',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onBg,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Color(0xFF4B5563),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: AppTheme.primary.withValues(alpha: 0.08),
                            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              AppNavigation.pushRoute(
                                context,
                                NotificationsScreen(userId: userId),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 13),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF064E3B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      size: 18,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Notifications',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onBg,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Color(0xFF4B5563),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: AppTheme.primary.withValues(alpha: 0.08),
                            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              AppNavigation.pushSecondary(
                                context,
                                title: 'Alert settings',
                                body: const NotificationSettingsScreen(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 13),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF451A03),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.settings_outlined,
                                      size: 18,
                                      color: Color(0xFFFCD34D),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Alert settings',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onBg,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Color(0xFF4B5563),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: AppTheme.primary.withValues(alpha: 0.08),
                            highlightColor: AppTheme.primary.withValues(alpha: 0.04),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              AppNavigation.pushSecondary(
                                context,
                                title: 'About',
                                body: const AboutScreen(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 13),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B0764),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Color(0xFFC084FC),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'About',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: onBg,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Color(0xFF4B5563),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (showReportExport) ...[
                          const SizedBox(height: 8),
                          Divider(
                            color: border,
                            height: 1,
                            thickness: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryContainer,
                                    surf,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: border,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.file_download_outlined,
                                              size: 16,
                                              color: Color(0xFF818CF8),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Export Report',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: onBg,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF & Excel formats',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: handleExportTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Export',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: border,
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: AppTheme.error.withValues(alpha: 0.08),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            await ref.read(authRepositoryProvider).signOut();
                            router.go('/login');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 13),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF450A0A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                    color: Color(0xFFFCA5A5),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Sign out',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AttendPro v1.0.0',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerMenuItem {
  const DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
}
