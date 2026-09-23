import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/utils/ui_helper.dart';
import '../../core/validators/validators.dart';
import '../../models/user_model.dart';

/// Sign Up registration screen (View).
///
/// Designed with reference to SmartAttend layout structure:
/// - Centered AppBar
/// - SingleChildScrollView with keyboardDismissBehavior
/// - Standardized input fields with prefix icons and password visibility toggles
/// - Primary Create Account button with loading state
/// - OR divider & Google SSO button
/// - Synchronized SharedPreferences session logic
/// - WorkBridge theme colors, validators, and Firebase backend
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      UiHelper.showSnackBar(
        context,
        'Passwords do not match. Please re-enter.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Coordinate with UserController for Firebase authentication & Firestore profile creation
      await context.read<UserController>().signUpWithFirebase(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );

      if (!mounted) return;
      final user = context.read<UserController>().user;
      final canonicalRole = user.canonicalRole ?? AppRoles.customer;

      // Persist session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppPreferences.keyRole, canonicalRole);
      await prefs.setBool(AppPreferences.keyIsLoggedIn, true);
      await prefs.setBool(AppPreferences.keyIsFirstInstall, false);
      await prefs.setBool(AppPreferences.keyIsLoggin, false);
      await prefs.setBool(AppPreferences.keyIsFirstLoggin, false);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final displayRole = AppRoles.displayName(canonicalRole);
      UiHelper.showSnackBar(
        context,
        'Account created successfully as $displayRole! Welcome to WorkBridge.',
      );

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
          "Sign Up",
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
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.015,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Animation / Branding Header
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.18,
                  child: UiHelper.lottieOrImage(
                    context: context,
                    imageAsset: 'assets/images/app_logo.png',
                    heightFraction: 0.14,
                    widthFraction: 0.70,
                    fallbackIcon: Icons.person_add_alt_1_rounded,
                    title: 'Join WorkBridge',
                    subtitle: 'Join the WorkBridge network today',
                  ),
                ),

                SizedBox(height: screenHeight * 0.012),

                Text(
                  'Get Started with WorkBridge',
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.005),

                Text(
                  'Create your profile to start exploring jobs or hiring',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.02),

                // Account Role Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildRoleOption('customer', 'Customer', Icons.person_rounded),
                      _buildRoleOption('service_provider', 'Provider', Icons.handyman_rounded),
                      _buildRoleOption('admin', 'Admin', Icons.shield_rounded),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  autofillHints: const [AutofillHints.name],
                  keyboardType: TextInputType.name,
                  validator: Validators.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    hintText: "Full Name",
                    hintStyle: const TextStyle(color: AppColors.secondaryText),
                    prefixIcon: const Icon(
                      Icons.person_outline,
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

                SizedBox(height: screenHeight * 0.015),

                // Email Input
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

                SizedBox(height: screenHeight * 0.015),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    hintText: "Phone Number",
                    hintStyle: const TextStyle(color: AppColors.secondaryText),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
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

                SizedBox(height: screenHeight * 0.015),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
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

                SizedBox(height: screenHeight * 0.015),

                // Confirm Password Input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    hintText: "Confirm Password",
                    hintStyle: const TextStyle(color: AppColors.secondaryText),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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

                SizedBox(height: screenHeight * 0.025),

                // Create Account Button
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
                          onPressed: _onSignUpPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Create Account",
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
                        "Google SSO registration is ready.",
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

                // Switch to Login
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
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
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String roleKey, String label, IconData icon) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppColors.card : AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.card : AppColors.secondaryText,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
