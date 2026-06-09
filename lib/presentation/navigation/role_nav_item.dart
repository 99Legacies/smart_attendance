import 'package:flutter/material.dart';

/// Bottom navigation entry with a synchronized page and destination.
class RoleNavItem {
  const RoleNavItem({
    required this.label,
    required this.page,
    required this.destination,
  });

  final String label;
  final Widget page;
  final NavigationDestination destination;
}
