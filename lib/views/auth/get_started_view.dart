import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/utils/ui_helper.dart';

/// Get Started onboarding screen (View).
///
/// Designed with reference to SmartAttend layout structure:
/// - Proportional AppSize responsive measurements
/// - Top section with centered animation container, title, and descriptive subtitle
/// - Full-width rounded bottom action button
/// - WorkBridge theme colors and branding
class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = AppSize.width(context);
    final double screenHeight = AppSize.height(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top content (Animation + Brand Title + Description)
              SizedBox(height: screenHeight * 0.005),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.32,
                    child: UiHelper.lottieOrImage(
                      context: context,
                      imageAsset: 'assets/images/app_logo.png',
                      heightFraction: 0.25,
                      widthFraction: 0.80,
                      fallbackIcon: Icons.handshake_rounded,
                      title: 'WorkBridge',
                      subtitle: 'Bridging Skills & Tomorrow',
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  Text(
                    'Welcome to\nWorkBridge',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.012),

                  Text(
                    'Experience trusted on-demand services, verified professionals, and seamless booking.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: AppColors.secondaryText,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Value proposition badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureBadge(context, Icons.verified_rounded, 'Verified Pros'),
                      _buildFeatureBadge(context, Icons.bolt_rounded, 'Instant Connect'),
                      _buildFeatureBadge(context, Icons.shield_rounded, 'Secure Platform'),
                    ],
                  ),
                ],
              ),

              // Bottom Action Button
              Container(
                width: double.infinity,
                height: screenHeight * 0.065,
                margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: AppColors.card,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.card,
                        size: screenWidth * 0.05,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }
}
