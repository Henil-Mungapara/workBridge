import 'package:flutter/material.dart';

/// Centralized currency constants and formatting utilities for WorkBridge.
/// Strictly enforces Indian Rupees (₹ - INR) across the entire application.
abstract final class AppCurrency {
  /// The official currency symbol for Indian Rupee.
  static const String symbol = '₹';

  /// Standard three-letter currency code for Indian Rupee.
  static const String code = 'INR';

  /// Full localized currency name.
  static const String name = 'Indian Rupee';

  /// The standard Material Design rounded icon for Indian Rupee.
  static const IconData icon = Icons.currency_rupee_rounded;

  /// Alternative standard icon without rounded styling if needed.
  static const IconData iconSharp = Icons.currency_rupee;

  /// Formats a numeric [amount] into an Indian Rupee string representation.
  /// Example:
  /// ```dart
  /// AppCurrency.format(1200) // '₹1,200.00'
  /// AppCurrency.format(4200, showDecimals: false) // '₹4,200'
  /// ```
  static String format(num amount, {bool showDecimals = true}) {
    final parts = amount.toStringAsFixed(showDecimals ? 2 : 0).split('.');
    final integerPart = _formatIndianGrouping(parts[0]);
    if (showDecimals && parts.length > 1) {
      return '$symbol$integerPart.${parts[1]}';
    }
    return '$symbol$integerPart';
  }

  /// Formats an hourly or unit rate in Indian Rupees.
  /// Example:
  /// ```dart
  /// AppCurrency.formatRate(450) // '₹450.00 / hour'
  /// ```
  static String formatRate(num amount, {String unit = 'hour'}) {
    return '${format(amount, showDecimals: true)} / $unit';
  }

  /// Internal helper to format integers using standard Indian numbering grouping:
  /// (e.g., 18,500, 1,00,000, 12,000).
  static String _formatIndianGrouping(String digits) {
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    var remaining = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (remaining.length > 2) {
      chunks.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      chunks.insert(0, remaining);
    }
    return '${chunks.join(',')},$lastThree';
  }
}
