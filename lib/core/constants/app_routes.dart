import 'package:flutter/material.dart';

import '../../views/admin/dashboard_view.dart';
import '../../views/admin/profile_view.dart';
import '../../views/auth/forgot_password_view.dart';
import '../../views/auth/get_started_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/privacy_policy_view.dart';
import '../../views/auth/signup_view.dart';
import '../../views/auth/splash_view.dart';
import '../../views/customer/customer_bookings_view.dart';
import '../../views/customer/dashboard_view.dart';
import '../../views/customer/profile_view.dart';
import '../../views/provider/dashboard_view.dart';
import '../../views/provider/profile_view.dart';

/// Centralized named routes for WORKBRIDGE.
abstract final class AppRoutes {
  /// Global navigator key allowing programmatic navigation without BuildContext,
  /// including remote role change auto-logout and redirect to Login.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ── Auth & Onboarding ────────────────────────────────────────────────
  static const String splash = '/';
  static const String getStarted = '/get-started';
  static const String privacyPolicy = '/privacy-policy';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Customer Views ───────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String customerDashboard = '/customer/dashboard';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String customerProfile = '/customer/profile';
  static const String editProfile = '/profile/edit';

  // ── Service Provider Views ───────────────────────────────────────────
  static const String providerDashboard = '/provider/dashboard';
  static const String providerProfile = '/provider/profile';

  // ── Admin Views ──────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProfile = '/admin/profile';

  // ── Services & Bookings ──────────────────────────────────────────────
  static const String serviceCategories = '/services';
  static const String serviceDetails = '/services/details';
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/details';
  static const String createBooking = '/bookings/create';

  // ── Route Factory ────────────────────────────────────────────────────
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashView(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        );

      case getStarted:
        return MaterialPageRoute(
          builder: (_) => const GetStartedView(),
          settings: settings,
        );

      case privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyView(),
          settings: settings,
        );

      case signup:
      case register:
        return MaterialPageRoute(
          builder: (_) => const SignUpView(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginView(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordView(),
          settings: settings,
        );

      // Customer routes
      case customerDashboard:
      case dashboard:
      case home:
        return MaterialPageRoute(
          builder: (_) => const DashboardView(),
          settings: settings,
        );

      case customerProfile:
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileView(),
          settings: settings,
        );

      case bookings:
        return MaterialPageRoute(
          builder: (_) => const CustomerBookingsView(),
          settings: settings,
        );

      // Service Provider routes
      case providerDashboard:
        return MaterialPageRoute(
          builder: (_) => const ProviderDashboardView(),
          settings: settings,
        );

      case providerProfile:
        return MaterialPageRoute(
          builder: (_) => const ProviderProfileView(),
          settings: settings,
        );

      // Administrator routes
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardView(),
          settings: settings,
        );

      case adminProfile:
        return MaterialPageRoute(
          builder: (_) => const AdminProfileView(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Navigation Error')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
