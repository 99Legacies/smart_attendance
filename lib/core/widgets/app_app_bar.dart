import 'package:flutter/material.dart';

/// App bar that follows [ThemeData.appBarTheme] (transparent on gradient shells).
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).appBarTheme;
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: theme.backgroundColor,
      foregroundColor: theme.foregroundColor,
      elevation: theme.elevation,
      scrolledUnderElevation: theme.scrolledUnderElevation,
      iconTheme: theme.iconTheme,
      actionsIconTheme: theme.actionsIconTheme,
      titleTextStyle: theme.titleTextStyle,
      systemOverlayStyle: theme.systemOverlayStyle,
    );
  }
}
