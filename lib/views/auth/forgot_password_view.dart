import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/validators/validators.dart';

/// Forgot Password screen (View).
///
/// Provides users with a secure, intuitive way to recover their WorkBridge account.
/// Fully integrated with Firebase Authentication's password reset email flow.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String _sentToEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onResetPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await context.read<UserController>().sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
        _sentToEmail = email;
      });

      UiHelper.showSnackBar(
        context,
        'Password reset link sent to $email ✉️',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UiHelper.showSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = AppSize.width(context);
    final double screenHeight = AppSize.height(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          "Forgot Password",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.02,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.02),

                          // Top Illustration / Icon Container
                          SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.18,
                            child: UiHelper.lottieOrImage(
                              context: context,
                              imageAsset: _emailSent ? null : 'assets/images/app_logo.png',
                              heightFraction: 0.14,
                              widthFraction: 0.70,
                              fallbackIcon: _emailSent
                                  ? Icons.mark_email_read_rounded
                                  : Icons.lock_reset_rounded,
                              title: _emailSent ? 'Check Your Inbox' : 'Account Recovery',
                              subtitle: _emailSent
                                  ? 'We sent a recovery link to your email'
                                  : 'We will help you regain account access',
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          Text(
                            _emailSent ? 'Email Sent Successfully!' : 'Reset Your Password',
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.008),

                          Text(
                            _emailSent
                                ? 'We have dispatched a password reset link to:\n$_sentToEmail\nPlease check your inbox and spam folder.'
                                : 'Enter your registered email address and we will send you a secure link to reset your password.',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          if (!_emailSent) ...[
                            // Email Input Field
                            TextFormField(
                              controller: _emailController,
                              autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                hintText: "Enter your registered email",
                                hintStyle: const TextStyle(color: AppColors.secondaryText),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primary,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.045,
                                  vertical: screenHeight * 0.018,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Submit Button
                            _isLoading
                                ? const CircularProgressIndicator(color: AppColors.primary)
                                : Container(
                                    width: double.infinity,
                                    height: screenHeight * 0.062,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _onResetPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        "Send Reset Link",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          color: AppColors.card,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                          ] else ...[
                            // Action buttons after email sent
                            Container(
                              width: double.infinity,
                              height: screenHeight * 0.062,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                                },
                                icon: const Icon(Icons.login_rounded, color: AppColors.card),
                                label: Text(
                                  "Back to Login",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    color: AppColors.card,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.015),

                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _emailSent = false;
                                });
                              },
                              child: Text(
                                "Did not receive the email? Try again",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: screenWidth * 0.036,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: screenHeight * 0.03),

                          // Return to Login link at footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Remember your password? ",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                                  minimumSize: const Size(40, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                                  }
                                },
                                child: Text(
                                  "Log In",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
