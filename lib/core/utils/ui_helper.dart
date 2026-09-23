import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'media_query_helper.dart';

/// Centralized UI helper containing all reusable widgets as **static functions**.
///
/// Written once here, called throughout the app to enforce consistent design,
/// smooth theming, and strict [MediaQuery]-driven responsive scaling.
abstract final class UiHelper {
  // ── Buttons ─────────────────────────────────────────────────────────────

  /// Standard primary elevated button scaled with [MediaQuery].
  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double widthFraction = 0.9,
    double heightFraction = 0.065,
    Color backgroundColor = AppColors.primary,
    Color textColor = AppColors.card,
  }) {
    final width = MediaQueryHelper.width(context, widthFraction);
    final height = MediaQueryHelper.height(context, heightFraction);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: height * 0.45,
                height: height * 0.45,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.card),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: height * 0.38, color: textColor),
                    SizedBox(width: width * 0.025),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppTextStyles.button.copyWith(
                        color: textColor,
                        fontSize: MediaQueryHelper.responsiveFont(context, 15),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Outlined button with responsive dimensions.
  static Widget outlinedButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    double widthFraction = 0.9,
    double heightFraction = 0.065,
    Color borderColor = AppColors.border,
    Color textColor = AppColors.primary,
  }) {
    final width = MediaQueryHelper.width(context, widthFraction);
    final height = MediaQueryHelper.height(context, heightFraction);

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height * 0.38, color: textColor),
              SizedBox(width: width * 0.025),
            ],
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.button.copyWith(
                  color: textColor,
                  fontSize: MediaQueryHelper.responsiveFont(context, 15),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact text button.
  static Widget textButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? style,
    Color? color,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQueryHelper.width(context, 0.03),
          vertical: MediaQueryHelper.height(context, 0.01),
        ),
      ),
      child: Text(
        text,
        style: style ??
            AppTextStyles.labelLarge.copyWith(
              color: color ?? AppColors.accent,
              fontSize: MediaQueryHelper.responsiveFont(context, 14),
            ),
      ),
    );
  }

  // ── Text Fields ─────────────────────────────────────────────────────────

  /// Centralized custom text input field.
  static Widget customTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    String? labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    int maxLines = 1,
    double widthFraction = 0.9,
  }) {
    return SizedBox(
      width: MediaQueryHelper.width(context, widthFraction),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            Text(
              labelText,
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: MediaQueryHelper.responsiveFont(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(height: MediaQueryHelper.height(context, 0.008)),
          ],
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: MediaQueryHelper.responsiveFont(context, 15),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText.withValues(alpha: 0.8),
                fontSize: MediaQueryHelper.responsiveFont(context, 14),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppColors.secondaryText,
                      size: MediaQueryHelper.responsiveFont(context, 20),
                    )
                  : null,
              suffixIcon: suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: MediaQueryHelper.width(context, 0.04),
                vertical: MediaQueryHelper.height(context, 0.018),
              ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                borderSide: const BorderSide(color: AppColors.error, width: 1.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Checkboxes ──────────────────────────────────────────────────────────

  /// Custom interactive checkbox with label widget and responsive layout.
  static Widget customCheckbox({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
    Color activeColor = AppColors.accent,
    double widthFraction = 0.9,
  }) {
    return Container(
      width: MediaQueryHelper.width(context, widthFraction),
      padding: EdgeInsets.symmetric(
        vertical: MediaQueryHelper.height(context, 0.006),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.secondaryText, width: 1.5),
              ),
            ),
            SizedBox(width: MediaQueryHelper.width(context, 0.03)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // ── Media & Lottie ──────────────────────────────────────────────────────

  /// Smart illustration/Lottie component.
  ///
  /// Supports:
  /// - Direct Lottie asset (`lottieAsset: 'assets/animations/signup.json'`)
  /// - Direct Lottie network URL (`lottieUrl: 'https://...'`)
  /// - Polished fallback animated/gradient container if no Lottie JSON is provided yet.
  static Widget lottieOrImage({
    required BuildContext context,
    String? lottieAsset,
    String? lottieUrl,
    String? imageAsset,
    IconData fallbackIcon = Icons.work_outline_rounded,
    double heightFraction = 0.22,
    double widthFraction = 0.85,
    String? title,
    String? subtitle,
  }) {
    final height = MediaQueryHelper.height(context, heightFraction);
    final width = MediaQueryHelper.width(context, widthFraction);

    Widget content;

    if (lottieAsset != null && lottieAsset.isNotEmpty) {
      content = Lottie.asset(
        lottieAsset,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackPlaceholder(context, height, width, fallbackIcon, title, subtitle),
      );
    } else if (lottieUrl != null && lottieUrl.isNotEmpty) {
      content = Lottie.network(
        lottieUrl,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackPlaceholder(context, height, width, fallbackIcon, title, subtitle),
      );
    } else if (imageAsset != null && imageAsset.isNotEmpty) {
      content = Image.asset(
        imageAsset,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackPlaceholder(context, height, width, fallbackIcon, title, subtitle),
      );
    } else {
      content = _buildFallbackPlaceholder(context, height, width, fallbackIcon, title, subtitle);
    }

    return Center(child: content);
  }

  static Widget _buildFallbackPlaceholder(
    BuildContext context,
    double height,
    double width,
    IconData icon,
    String? title,
    String? subtitle,
  ) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentLight.withValues(alpha: 0.9),
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.03,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(height * 0.08),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: height * 0.28,
                  color: AppColors.accent,
                ),
              ),
              if (title != null) ...[
                SizedBox(height: height * 0.03),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQueryHelper.responsiveFont(context, 15),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (subtitle != null) ...[
                SizedBox(height: height * 0.015),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: MediaQueryHelper.responsiveFont(context, 11.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Branding & Headers ──────────────────────────────────────────────────

  /// WorkBridge logo header with responsive brand logo image and typography.
  static Widget appBrandLogo({
    required BuildContext context,
    double sizeFraction = 0.09,
    bool showText = true,
    Color? iconColor,
  }) {
    final size = MediaQueryHelper.height(context, sizeFraction);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.work_outline_rounded,
                size: size * 0.55,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: MediaQueryHelper.height(context, 0.012)),
          Text(
            'WORKBRIDGE',
            style: AppTextStyles.headlineSmall.copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: MediaQueryHelper.responsiveFont(context, 20),
            ),
          ),
          Text(
            'Connecting Opportunities & Talent',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
              fontSize: MediaQueryHelper.responsiveFont(context, 12),
            ),
          ),
        ],
      ],
    );
  }

  // ── Spacers & Containers ────────────────────────────────────────────────

  /// Responsive vertical space using [MediaQueryHelper].
  static Widget verticalSpace(BuildContext context, double fraction) {
    return MediaQueryHelper.verticalSpace(context, fraction);
  }

  /// Responsive horizontal space using [MediaQueryHelper].
  static Widget horizontalSpace(BuildContext context, double fraction) {
    return MediaQueryHelper.horizontalSpace(context, fraction);
  }

  /// Polished elevated surface card.
  static Widget customCard({
    required BuildContext context,
    required Widget child,
    double widthFraction = 0.9,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color backgroundColor = AppColors.card,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: MediaQueryHelper.width(context, widthFraction),
      margin: margin ??
          EdgeInsets.symmetric(
            vertical: MediaQueryHelper.height(context, 0.01),
          ),
      padding: padding ??
          EdgeInsets.all(MediaQueryHelper.width(context, 0.04)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Centralized custom AppBar.
  static PreferredSizeWidget customAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Color backgroundColor = AppColors.card,
  }) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          fontSize: MediaQueryHelper.responsiveFont(context, 18),
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
    );
  }

  /// Uniform SnackBar for alerts and notifications.
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.card,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
      ),
    );
  }

  /// Displays an executive role verification failure alert dialog.
  /// Triggered when an authenticated user has an unrecognized, misspelled, or unauthorized role.
  static Future<void> showRoleErrorDialog({
    required BuildContext context,
    required String? invalidRole,
    VoidCallback? onContactAdmin,
  }) async {
    final displayRole = (invalidRole != null && invalidRole.trim().isNotEmpty)
        ? invalidRole.trim()
        : 'Unassigned / Null';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          backgroundColor: AppColors.card,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield warning icon badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Role Verification Error',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: MediaQueryHelper.responsiveFont(dialogContext, 18),
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                'Access Restricted',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQueryHelper.responsiveFont(dialogContext, 12),
                  color: AppColors.error,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Highlight of rejected role
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Detected Role on Account:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: MediaQueryHelper.responsiveFont(dialogContext, 11),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$displayRole"',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: MediaQueryHelper.responsiveFont(dialogContext, 15),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Explanation & System Rules
              Text(
                'WorkBridge strictly recognizes only three system roles:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: MediaQueryHelper.responsiveFont(dialogContext, 12.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Allowed Roles Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _roleBadge('Customer', Icons.person_rounded),
                  _roleBadge('Service_Provider', Icons.handyman_rounded),
                  _roleBadge('Admin', Icons.shield_rounded),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Please contact the system administrator or IT helpdesk to update your account role permissions.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: MediaQueryHelper.responsiveFont(dialogContext, 11.5),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Back to Login',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.card,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (onContactAdmin != null) {
                        onContactAdmin();
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Row(
                              children: [
                                Icon(Icons.support_agent_rounded, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Administrator Contact'),
                              ],
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('For role permission adjustments, please contact:'),
                                SizedBox(height: 12),
                                Text('• Email: admin@workbridge.pro', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('• Support: support@workbridge.pro', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('• IT Desk: +1 (800) 555-WORK', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: Text(
                      'Contact Admin',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.card,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget _roleBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search & Sort Bar ───────────────────────────────────────────────────

  /// Standardized responsive Search and Sort Bar used across views.
  static Widget searchAndSortBar({
    required BuildContext context,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String hintText,
    required String selectedSort,
    required List<String> sortOptions,
    required ValueChanged<String> onSortChanged,
    VoidCallback? onClear,
    double widthFraction = 0.91,
  }) {
    return Container(
      width: MediaQueryHelper.width(context, widthFraction),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          // Search Box
          Expanded(
            child: Container(
              height: MediaQueryHelper.height(context, 0.055),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: MediaQueryHelper.responsiveFont(context, 13.5),
                  color: AppColors.mainText,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText.withValues(alpha: 0.8),
                    fontSize: MediaQueryHelper.responsiveFont(context, 13),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: MediaQueryHelper.responsiveFont(context, 20),
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: MediaQueryHelper.responsiveFont(context, 18),
                            color: AppColors.secondaryText,
                          ),
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                            if (onClear != null) onClear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: MediaQueryHelper.width(context, 0.03),
                    vertical: MediaQueryHelper.height(context, 0.012),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: MediaQueryHelper.width(context, 0.025)),
          // Sorting Button
          PopupMenuButton<String>(
            tooltip: 'Sort list',
            initialValue: selectedSort,
            onSelected: onSortChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 4,
            color: AppColors.card,
            itemBuilder: (context) {
              return sortOptions.map((option) {
                final isSelected = option == selectedSort;
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: MediaQueryHelper.responsiveFont(context, 13),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.accent : AppColors.mainText,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              height: MediaQueryHelper.height(context, 0.055),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQueryHelper.width(context, 0.032),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: AppColors.card,
                    size: MediaQueryHelper.responsiveFont(context, 18),
                  ),
                  SizedBox(width: MediaQueryHelper.width(context, 0.015)),
                  Text(
                    'Sort',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.card,
                      fontSize: MediaQueryHelper.responsiveFont(context, 12.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  /// Redesigned Confirmation Alert Dialog styled with APK root color and smooth elevation.
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Log Out',
    String cancelText = 'Cancel',
    IconData icon = Icons.logout_rounded,
    Color iconColor = AppColors.primary,
    Color confirmButtonColor = AppColors.primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.18),
        titlePadding: EdgeInsets.fromLTRB(
          MediaQueryHelper.width(ctx, 0.06),
          MediaQueryHelper.height(ctx, 0.028),
          MediaQueryHelper.width(ctx, 0.06),
          0,
        ),
        contentPadding: EdgeInsets.fromLTRB(
          MediaQueryHelper.width(ctx, 0.06),
          MediaQueryHelper.height(ctx, 0.015),
          MediaQueryHelper.width(ctx, 0.06),
          MediaQueryHelper.height(ctx, 0.02),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          MediaQueryHelper.width(ctx, 0.06),
          0,
          MediaQueryHelper.width(ctx, 0.06),
          MediaQueryHelper.height(ctx, 0.024),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: MediaQueryHelper.responsiveFont(ctx, 22),
              ),
            ),
            SizedBox(width: MediaQueryHelper.width(ctx, 0.03)),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: MediaQueryHelper.responsiveFont(ctx, 17),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondaryText,
            fontSize: MediaQueryHelper.responsiveFont(ctx, 13.5),
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryText,
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQueryHelper.height(ctx, 0.014),
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQueryHelper.responsiveFont(ctx, 13.5),
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQueryHelper.width(ctx, 0.03)),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor,
                    foregroundColor: AppColors.card,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQueryHelper.height(ctx, 0.014),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.card,
                      fontWeight: FontWeight.w700,
                      fontSize: MediaQueryHelper.responsiveFont(ctx, 13.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Logout Action Button ────────────────────────────────────────────────

  /// Standardized Logout Button styled with APK root color and matching shadow.
  static Widget logoutButton({
    required BuildContext context,
    required VoidCallback onPressed,
    String label = 'Log Out',
    double widthFraction = 0.91,
    double heightFraction = 0.062,
  }) {
    final width = MediaQueryHelper.width(context, widthFraction);
    final height = MediaQueryHelper.height(context, heightFraction);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, color: AppColors.card),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: AppColors.card,
            fontSize: MediaQueryHelper.responsiveFont(context, 15),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
