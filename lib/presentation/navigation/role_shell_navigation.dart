import 'package:flutter/material.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_nav_item.dart';

/// Validates and clamps shell tab index; logs state for debugging.
class RoleShellNavigation {
  RoleShellNavigation({required this.logTag});

  final String logTag;
  int _selectedIndex = 0;
  UserRole? _activeRole;

  int get selectedIndex => _selectedIndex;

  /// Call on every build before using [selectedIndex] or page lists.
  int resolve({
    required UserRole role,
    required List<RoleNavItem> navItems,
  }) {
    final length = navItems.length;

    if (_activeRole != role) {
      debugPrint(
        '[$logTag] role changed ${_activeRole?.name} -> ${role.name}, '
        'resetting index from $_selectedIndex to 0',
      );
      _activeRole = role;
      _selectedIndex = 0;
    } else if (length == 0) {
      if (_selectedIndex != 0) {
        debugPrint('[$logTag] empty navItems, resetting index to 0');
      }
      _selectedIndex = 0;
    } else if (_selectedIndex >= length) {
      debugPrint(
        '[$logTag] index $_selectedIndex >= length $length, resetting to 0',
      );
      _selectedIndex = 0;
    } else {
      final clamped = _selectedIndex.clamp(0, length - 1);
      if (clamped != _selectedIndex) {
        debugPrint('[$logTag] clamped index $_selectedIndex -> $clamped');
        _selectedIndex = clamped;
      }
    }

    debugPrint(
      '[$logTag] selectedIndex=$_selectedIndex navItems.length=$length '
      'role=${role.name}',
    );
    return _selectedIndex;
  }

  void select(int index, int length) {
    if (length <= 0) {
      _selectedIndex = 0;
    } else {
      _selectedIndex = index.clamp(0, length - 1);
    }
    debugPrint(
      '[$logTag] select -> $_selectedIndex (requested $index, length $length)',
    );
  }

  String labelAt(List<RoleNavItem> navItems, int index) {
    if (navItems.isEmpty) return '';
    final safe = index.clamp(0, navItems.length - 1);
    return navItems[safe].label;
  }

  List<Widget> pagesFrom(List<RoleNavItem> navItems) {
    return navItems.map((item) => item.page).toList();
  }

  List<NavigationDestination> destinationsFrom(List<RoleNavItem> navItems) {
    return navItems.map((item) => item.destination).toList();
  }
}
