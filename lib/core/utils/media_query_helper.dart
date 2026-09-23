import 'package:flutter/material.dart';

/// Responsive dimension helper entirely driven by [MediaQuery].
///
/// Ensures all widths, heights, and spaces are computed as proportional
/// fractions of the device viewport rather than fixed magic numbers.
abstract final class MediaQueryHelper {
  /// Returns a fraction of screen height (e.g. 0.1 = 10% of screen height).
  static double height(BuildContext context, [double fraction = 1.0]) {
    return MediaQuery.sizeOf(context).height * fraction;
  }

  /// Returns a fraction of screen width (e.g. 0.85 = 85% of screen width).
  static double width(BuildContext context, [double fraction = 1.0]) {
    return MediaQuery.sizeOf(context).width * fraction;
  }

  /// Full screen height.
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Full screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Top safe area padding (e.g. notch / status bar).
  static double paddingTop(BuildContext context) {
    return MediaQuery.paddingOf(context).top;
  }

  /// Bottom safe area padding (e.g. home indicator).
  static double paddingBottom(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom;
  }

  /// Responsive vertical space widget based on screen height percentage.
  static Widget verticalSpace(BuildContext context, double fraction) {
    return SizedBox(height: height(context, fraction));
  }

  /// Responsive horizontal space widget based on screen width percentage.
  static Widget horizontalSpace(BuildContext context, double fraction) {
    return SizedBox(width: width(context, fraction));
  }

  /// Proportionally scaled font size based on viewport width.
  static double responsiveFont(BuildContext context, double baseFontSize) {
    final scale = MediaQuery.sizeOf(context).width / 390.0;
    final clampedScale = scale.clamp(0.85, 1.35);
    return baseFontSize * clampedScale;
  }

  /// True when device is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }
}

/// Convenience extensions directly on [BuildContext] for responsive layouts.
extension ResponsiveContextX on BuildContext {
  /// Screen width scaled by fraction (e.g. `context.widthPct(0.9)`).
  double widthPct(double fraction) => MediaQueryHelper.width(this, fraction);

  /// Screen height scaled by fraction (e.g. `context.heightPct(0.3)`).
  double heightPct(double fraction) => MediaQueryHelper.height(this, fraction);

  /// Full screen width.
  double get screenWidth => MediaQueryHelper.screenWidth(this);

  /// Full screen height.
  double get screenHeight => MediaQueryHelper.screenHeight(this);

  /// Top safe area inset.
  double get safePaddingTop => MediaQueryHelper.paddingTop(this);

  /// Bottom safe area inset.
  double get safePaddingBottom => MediaQueryHelper.paddingBottom(this);

  /// Responsive vertical spacer (e.g. `context.vSpace(0.02)`).
  Widget vSpace(double fraction) => MediaQueryHelper.verticalSpace(this, fraction);

  /// Responsive horizontal spacer (e.g. `context.hSpace(0.04)`).
  Widget hSpace(double fraction) => MediaQueryHelper.horizontalSpace(this, fraction);

  /// Responsive font size.
  double respFont(double baseSize) => MediaQueryHelper.responsiveFont(this, baseSize);
}
