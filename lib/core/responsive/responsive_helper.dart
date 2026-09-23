import 'package:flutter/material.dart';

/// Breakpoint-based responsive helpers for WORKBRIDGE.
///
/// Usage:
/// ```dart
/// if (ResponsiveHelper.isMobile(context)) { ... }
/// ```
///
/// Prefer Flutter's natural layout system (Flexible, Expanded, LayoutBuilder)
/// over explicit breakpoint checks. Use these helpers only when layout logic
/// genuinely diverges between form factors.
abstract final class ResponsiveHelper {
  // ── Breakpoints ────────────────────────────────────────────────────────
  static const double _mobileMax = 600;
  static const double _tabletMax = 1024;

  /// True when the shortest side of the screen is ≤ 600 dp.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide <= _mobileMax;

  /// True when the shortest side is between 601 and 1024 dp.
  static bool isTablet(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return shortest > _mobileMax && shortest <= _tabletMax;
  }

  /// True when the shortest side exceeds 1024 dp.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide > _tabletMax;

  // ── Convenience ────────────────────────────────────────────────────────
  /// Full screen width.
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Full screen height.
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
}
