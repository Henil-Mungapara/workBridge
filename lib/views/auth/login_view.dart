import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/services/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/validators/validators.dart';
import '../../models/user_model.dart';

/// Login screen (View).
///
/// Designed with reference to SmartAttend layout structure:
/// - Centered AppBar
/// - LayoutBuilder + SingleChildScrollView with keyboardDismissBehavior
/// - ConstrainedBox & IntrinsicHeight with AutofillGroup
/// - Email & Password inputs with prefix icons & password toggle
/// - Auxiliary options: OTP / Forgot Password
/// - Primary Login button with loading state
/// - OR divider & Google SSO button
/// - Synchronized SharedPreferences session logic
/// - WorkBridge theme colors and branding
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    if (_emailController.text.trim().isNotEmpty &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Coordinate with UserController for Firebase authentication
      await context.read<UserController>().loginWithFirebase(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      final user = context.read<UserController>().user;
      final canonicalRole = user.canonicalRole;

      if (canonicalRole == null) {
        setState(() => _isLoading = false);
        UiHelper.showSnackBar(
          context,
          "Access Denied: Unrecognized account role '${user.role}'. Only Customer, Service_Provider, and Admin are permitted.",
          isError: true,
        );
        UiHelper.showRoleErrorDialog(
          context: context,
          invalidRole: user.role,
        );
        return;
      }

      // Persist session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppPreferences.keyRole, canonicalRole);
      await prefs.setBool(AppPreferences.keyIsLoggedIn, true);
      await prefs.setBool(AppPreferences.keyIsFirstInstall, false);
      await prefs.setBool(AppPreferences.keyIsLoggin, false);
      await prefs.setBool(AppPreferences.keyIsFirstLoggin, false);

      if (!mounted) return;
      setState(() => _isLoading = false);

      UiHelper.showSnackBar(context, 'Login Successful 🎉');

      // Redirect to role-based Dashboard
      if (canonicalRole == AppRoles.admin) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.adminDashboard,
          (route) => false,
        );
      } else if (canonicalRole == AppRoles.serviceProvider) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.providerDashboard,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.customerDashboard,
          (route) => false,
        );
      }
    } on AppRoleException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UiHelper.showSnackBar(
        context,
        "Access Denied: Unrecognized account role '${e.attemptedRole}'. Please contact the administrator.",
        isError: true,
      );
      UiHelper.showRoleErrorDialog(
        context: context,
        invalidRole: e.attemptedRole,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception:', '').trim();
      UiHelper.showSnackBar(context, errorMsg, isError: true);
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
          "Login",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
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

                          // Top Illustration / Animation Container
                          SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.18,
                            child: UiHelper.lottieOrImage(
                              context: context,
                              imageAsset: 'assets/images/app_logo.png',
                              heightFraction: 0.14,
                              widthFraction: 0.70,
                              fallbackIcon: Icons.lock_open_rounded,
                              title: 'Welcome Back',
                              subtitle: 'Access your work network and jobs',
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          Text(
                            'Log In to Your Account',
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.006),

                          Text(
                            'Enter your registered email and password',
                            style: TextStyle(
                              fontSize: screenWidth * 0.036,
                              color: AppColors.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: screenHeight * 0.025),

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
                              hintText: "Email Address",
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

                          SizedBox(height: screenHeight * 0.018),

                          // Password Input Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            validator: Validators.password,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.card,
                              hintText: "Password",
                              hintStyle: const TextStyle(color: AppColors.secondaryText),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.secondaryText,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
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

                          SizedBox(height: screenHeight * 0.01),

                          // Forgot Password Button (Right Aligned)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          // Primary Login Button
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
                                    onPressed: _onLoginPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      "Log In",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        color: AppColors.card,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),

                          SizedBox(height: screenHeight * 0.02),

                          // OR Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppColors.border,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                ),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: screenWidth * 0.036,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppColors.border,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          // Google SSO Button
                          SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.06,
                            child: OutlinedButton(
                              onPressed: () {
                                UiHelper.showSnackBar(
                                  context,
                                  "Google SSO is ready for connected accounts.",
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.card,
                                side: const BorderSide(color: AppColors.border, width: 1.2),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google.png',
                                      height: 20,
                                      width: 20,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.g_mobiledata_rounded,
                                        size: 24,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.025),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: AppColors.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Switch to Sign Up
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
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
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
                                  },
                                  child: Text(
                                    "Sign Up",
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
                          ),

                          SizedBox(height: screenHeight * 0.025),
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
