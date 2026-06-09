import 'package:flutter/material.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_nav_item.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_navigation.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_app_bar.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_bottom_nav.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_scaffold.dart';
import 'package:smart_attendance/presentation/widgets/design_system/shell_tab_body.dart';

/// Role shell with synchronized bottom nav pages and safe index handling.
class RoleShellScaffold extends StatefulWidget {
  const RoleShellScaffold({
    super.key,
    required this.role,
    required this.navItems,
    required this.navigation,
    this.drawer,
    this.appBarActions = const [],
    this.titlePrefix,
    this.userName,
    this.avatarUrl,
  });

  final UserRole role;
  final List<RoleNavItem> navItems;
  final RoleShellNavigation navigation;
  final Widget? drawer;
  final List<Widget> appBarActions;
  final String? titlePrefix;
  final String? userName;
  final String? avatarUrl;

  @override
  State<RoleShellScaffold> createState() => RoleShellScaffoldState();
}

class RoleShellScaffoldState extends State<RoleShellScaffold> {
  void navigateToTab(int index) {
    setState(() {
      widget.navigation.select(index, widget.navItems.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems;
    final safeIndex = widget.navigation.resolve(
      role: widget.role,
      navItems: navItems,
    );
    final titleLabel = widget.navigation.labelAt(navItems, safeIndex);
    final title = widget.titlePrefix == null
        ? titleLabel
        : '${widget.titlePrefix}$titleLabel';

    final pages = widget.navigation.pagesFrom(navItems);
    final destinations = widget.navigation.destinationsFrom(navItems);

    return ApScaffold(
      drawer: widget.drawer,
      appBar: ApAppBar(
        title: Text(title),
        userName: widget.userName,
        role: widget.role,
        avatarUrl: widget.avatarUrl,
        actions: widget.appBarActions,
      ),
      body: navItems.isEmpty
          ? const Center(child: Text('No navigation items'))
          : SizedBox.expand(
              child: IndexedStack(
                index: safeIndex,
                children: [
                  for (final page in pages) ShellTabBody(child: page),
                ],
              ),
            ),
      bottomNavigationBar: navItems.isEmpty
          ? null
          : ApBottomNav(
              selectedIndex: safeIndex,
              onSelected: (i) {
                setState(() {
                  widget.navigation.select(i, navItems.length);
                });
              },
              destinations: destinations,
            ),
    );
  }
}
