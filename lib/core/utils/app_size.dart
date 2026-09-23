import 'package:flutter/material.dart';

import 'media_query_helper.dart';

/// Proportional screen dimension helper delegating to [MediaQueryHelper].
abstract final class AppSize {
  /// Returns screen width in logical pixels.
  static double width(BuildContext context) => MediaQueryHelper.screenWidth(context);

  /// Returns screen height in logical pixels.
  static double height(BuildContext context) => MediaQueryHelper.screenHeight(context);
}
