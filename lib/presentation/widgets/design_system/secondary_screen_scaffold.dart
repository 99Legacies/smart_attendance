import 'package:flutter/material.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_app_bar.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_scaffold.dart';

/// Single scaffold + app bar for routes pushed from drawer or shell.
class SecondaryScreenScaffold extends StatelessWidget {
  const SecondaryScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return ApScaffold(
      appBar: ApAppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: body,
    );
  }
}
