import 'package:flutter/material.dart';

/// Centralized color palette for WORKBRIDGE.
///
/// Designed to enterprise executive standards:
/// - Midnight Sapphire primary for authority and prestige
/// - Electric Cyan-Teal accent for vibrancy and trust
/// - Clean Slate background and Pure White elevated cards
/// - Strict contrast accessibility
abstract final class AppColors {
  // ── Primary ────────────────────────────────────────────────────────────
  /// Midnight Sapphire — enterprise branding, navigation, primary actions.
  static const Color primary = Color(0xFF0A192F);

  /// Slate Navy — secondary primary variant for headers and hero cards.
  static const Color primaryLight = Color(0xFF1E293B);

  /// Deep Navy Tint — very subtle brand tinted background.
  static const Color primarySubtle = Color(0xFF0F172A);

  // ── Accent ─────────────────────────────────────────────────────────────
  /// Vibrant Cyan-Teal — highlights, active states, key CTAs.
  static const Color accent = Color(0xFF00A896);

  /// Mint Ice — soft accent chips, badge backgrounds, pill highlights.
  static const Color accentLight = Color(0xFFE6FFFA);

  /// Deep Teal — dark accent variant for high-contrast text on light teal.
  static const Color accentDark = Color(0xFF028090);

  // ── Surfaces ───────────────────────────────────────────────────────────
  /// Slate Off-White — app scaffold background.
  static const Color background = Color(0xFFF8FAFC);

  /// Pure White — cards, sheets, dialogs, and elevated surfaces.
  static const Color card = Color(0xFFFFFFFF);

  /// Card Surface Highlight — subtle card hover / active fill.
  static const Color cardAlt = Color(0xFFF1F5F9);

  // ── Text ───────────────────────────────────────────────────────────────
  /// Deep Obsidian — primary headings and high-emphasis body text.
  static const Color mainText = Color(0xFF0F172A);

  /// Cool Slate — secondary/helper text, captions, subtitles.
  static const Color secondaryText = Color(0xFF64748B);

  /// Muted Slate — placeholder hints, disabled text.
  static const Color mutedText = Color(0xFF94A3B8);

  // ── Borders & Dividers ─────────────────────────────────────────────────
  /// Subtle Slate Border — clean card borders, input borders, separators.
  static const Color border = Color(0xFFE2E8F0);

  /// Focused Border — subtle accent border.
  static const Color borderFocused = Color(0xFF00A896);

  // ── Semantic ───────────────────────────────────────────────────────────
  /// Emerald Green — success confirmations, verified badges, positive balance.
  static const Color success = Color(0xFF10B981);

  /// Crimson Rose — error alerts, destructive actions, logout.
  static const Color error = Color(0xFFEF4444);

  /// Amber Gold — warnings, pending reviews, star ratings.
  static const Color warning = Color(0xFFF59E0B);

  /// Info Sky — informational alerts, notices.
  static const Color info = Color(0xFF0284C7);

  // ── Gradients ──────────────────────────────────────────────────────────
  /// Executive Hero Gradient — used on primary cards and brand headers.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A192F),
      Color(0xFF1E3A5F),
    ],
  );

  /// Cyan-Teal Accent Gradient — used on high-energy action elements.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A896),
      Color(0xFF028090),
    ],
  );

  /// Surface Glass Gradient — soft subtle card gradient.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  // ── Shadows ────────────────────────────────────────────────────────────
  /// Soft card shadow for subtle depth.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Floating element shadow (FABs, primary buttons).
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A0A192F),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ── Backward-compatible Aliases ─────────────────────────────────────────
  static const Color primaryText = mainText;
  static const Color divider = border;
}
