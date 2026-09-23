import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../models/user_model.dart';

/// 3-second animated Splash Screen (View).
///
/// Designed with reference to the clean SmartAttend layout structure:
/// - SingleChildScrollView with ConstrainedBox & IntrinsicHeight
/// - Centralized brand presentation and proportional spacing
/// - Bottom LinearProgressIndicator
/// - Strict SharedPreferences status check logic (isFirstInstall, isLoggedIn, role)
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _checkUserStatus();
  }

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.90,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  ));

  /// Checks persistent session state, restores user from Firebase, and routes the user.
  Future<void> _checkUserStatus() async {
    // Concurrently run 3-second splash delay while restoring live Firebase session
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      context.read<UserController>().restoreUserSession(),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;

    final sessionRestored = results[1] as bool;
    final prefs = results[2] as SharedPreferences;

    final bool isLoggedIn = prefs.getBool(AppPreferences.keyIsLoggedIn) ??
        (!(prefs.getBool(AppPreferences.keyIsLoggin) ?? true));

    // 1. If an active session is restored from Firebase or SharedPreferences, navigate to role's panel
    if (sessionRestored || isLoggedIn) {
      final user = context.read<UserController>().user;
      final prefRole = prefs.getString(AppPreferences.keyRole);
      final String determinedRole = (prefRole != null && prefRole.isNotEmpty)
          ? prefRole
          : (user.uid.isNotEmpty && user.role.isNotEmpty ? user.role : AppRoles.customer);
      final canonicalRole = AppRoles.canonicalize(determinedRole);

      // If role is invalid or unrecognized, revoke session and route to login
      if (canonicalRole == null) {
        await context.read<UserController>().logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      if (canonicalRole == AppRoles.admin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else if (canonicalRole == AppRoles.serviceProvider) {
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.customerDashboard);
      }
      return;
    }

    // 2. If not logged in, check if first install onboarding is needed
    final bool isFirstInstall = prefs.getBool(AppPreferences.keyIsFirstInstall) ??
        prefs.getBool(AppPreferences.keyIsFirstLoggin) ??
        true;

    if (isFirstInstall) {
      Navigator.pushReplacementNamed(context, AppRoutes.getStarted);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = AppSize.width(context);
    final double h = AppSize.height(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.14),

                      // Brand Logo Hero with smooth entrance
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Center(
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              height: h * 0.22,
                              width: w * 0.75,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.035),

                      // Brand Title
                      Text(
                        "WORKBRIDGE",
                        style: TextStyle(
                          fontSize: w * 0.08,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 3,
                        ),
                      ),

                      SizedBox(height: h * 0.01),

                      // Subtitle
                      Text(
                        "Bridging Skills & Tomorrow",
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const Spacer(),

                      // Progress Indicator
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.22),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            minHeight: 5,
                            color: AppColors.accent,
                            backgroundColor: AppColors.accentLight,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.08),
                    ],
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
