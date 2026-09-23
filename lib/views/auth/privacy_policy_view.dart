import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';

/// Privacy Policy & Terms screen (View).
///
/// Designed with reference to SmartAttend layout structure:
/// - Centered AppBar
/// - Scrollable policy text container
/// - Two CheckboxListTile acceptance items
/// - SharedPreferences update (isFirstInstall: false) on proceed
/// - WorkBridge theme colors and branding
class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyIsFirstInstall, false);
    await prefs.setBool(AppPreferences.keyIsFirstLoggin, false);

    if (!mounted) return;
    context.read<UserController>().setTermsAccepted(true);

    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final double w = AppSize.width(context);
    final double h = AppSize.height(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy & Terms',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: w * 0.048,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.05,
            vertical: h * 0.015,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "WorkBridge Privacy Policy & Terms",
                          style: TextStyle(
                            fontSize: w * 0.046,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: h * 0.004),
                        Text(
                          "Please review our policy guidelines and accept below to proceed.",
                          style: TextStyle(
                            fontSize: w * 0.033,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.015),

              // Scrollable Terms Container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(w * 0.045),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "1. Information We Collect",
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: h * 0.006),
                        Text(
                          "We collect your account name, email address, and phone number to verify identity and match you with local service providers and clients.",
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: AppColors.mainText,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: h * 0.018),

                        Text(
                          "2. How We Use Information",
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: h * 0.006),
                        Text(
                          "Your information enables booking scheduling, provider communication, rating transparency, and account management.",
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: AppColors.mainText,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: h * 0.018),

                        Text(
                          "3. Data Protection & Privacy",
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: h * 0.006),
                        Text(
                          "WorkBridge uses encrypted communication and does not sell your personal data to third parties. You may update or delete your account at any time.",
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: AppColors.mainText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // Two CheckboxListTile widgets
              CheckboxListTile(
                activeColor: AppColors.primary,
                checkColor: AppColors.card,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  "I agree to the Terms of Service & User Guidelines",
                  style: TextStyle(
                    fontSize: w * 0.036,
                    color: AppColors.mainText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                activeColor: AppColors.primary,
                checkColor: AppColors.card,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  "I agree to the Privacy Policy & Data Processing",
                  style: TextStyle(
                    fontSize: w * 0.036,
                    color: AppColors.mainText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _agreePrivacy,
                onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              SizedBox(height: h * 0.015),

              // Bottom Action Button
              SizedBox(
                width: double.infinity,
                height: h * 0.062,
                child: ElevatedButton(
                  onPressed: _agreeTerms && _agreePrivacy ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    elevation: _agreeTerms && _agreePrivacy ? 2 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: w * 0.045,
                      color: _agreeTerms && _agreePrivacy
                          ? AppColors.card
                          : AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
