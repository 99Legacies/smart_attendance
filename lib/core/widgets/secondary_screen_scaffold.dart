import 'package:flutter/material.dart';
import 'package:smart_attendance/core/widgets/app_app_bar.dart';
import 'package:smart_attendance/core/widgets/gradient_scaffold.dart';

/// Single scaffold + app bar for routes pushed from drawer or shell (no nesting).
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
    return GradientScaffold(
      appBar: AppAppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: body,
    );
  }
}
