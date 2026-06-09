import 'package:flutter/material.dart';

/// Wraps shell tab content so [Column] + [Expanded] and lists get a bounded height.
///
/// Used as a child of [IndexedStack] with [StackFit.expand] in role shells.
class ShellTabBody extends StatelessWidget {
  const ShellTabBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        if (!maxHeight.isFinite || maxHeight <= 0) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          );
        }

        return SizedBox(
          height: maxHeight,
          width: maxWidth.isFinite ? maxWidth : null,
          child: child,
        );
      },
    );
  }
}
