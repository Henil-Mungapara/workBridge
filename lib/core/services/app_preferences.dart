import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import '../constants/app_routes.dart';

/// Centralized manager for persistent SharedPreferences session flags and routing logic.
///
/// Follows the reference model:
/// - [isFirstInstall] / [isFirstLoggin]: indicates initial onboarding required (defaults to true).
/// - [isLoggedIn] / [isLoggin]: indicates active authenticated session (defaults to false).
/// - [role]: stores the user's role ('customer', 'service_provider', or 'admin').
abstract final class AppPreferences {
  // ── Keys ───────────────────────────────────────────────────────────────
  static const String keyIsFirstInstall = 'isFirstInstall';
  static const String keyIsFirstLoggin = 'isFirstLoggin'; // Backwards compatibility alias
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyIsLoggin = 'isLoggin'; // Backwards compatibility alias (!isLoggedIn)
  static const String keyIsLogOut = 'isLoggOut';
  static const String keyRole = 'role';
  static const String keyUid = 'uid';
  static const String keyUserName = 'userName';
  static const String keyUserEmail = 'userEmail';
  static const String keyUserPhone = 'userPhone';

  // ── Variable 1: isFirstInstall / isFirstLoggin ──────────────────────────
  /// Returns true if this is the first install / initial onboarding flow (defaults to true).
  static Future<bool> getIsFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsFirstInstall) ??
        prefs.getBool(keyIsFirstLoggin) ??
        true;
  }

  /// Alias for backward compatibility.
  static Future<bool> getIsFirstLoggin() => getIsFirstInstall();

  /// Sets isFirstInstall and synchronizes isFirstLoggin.
  static Future<void> setIsFirstInstall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsFirstInstall, value);
    await prefs.setBool(keyIsFirstLoggin, value);
  }

  /// Alias for backward compatibility.
  static Future<void> setIsFirstLoggin(bool value) => setIsFirstInstall(value);

  // ── Variable 2: isLoggedIn / isLoggin / isLoggOut ──────────────────────
  /// Returns true if user is currently authenticated and logged in (defaults to false).
  static Future<bool> getIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(keyIsLoggedIn)) {
      return prefs.getBool(keyIsLoggedIn) ?? false;
    }
    if (prefs.containsKey(keyIsLoggin)) {
      return !(prefs.getBool(keyIsLoggin) ?? true);
    }
    return false;
  }

  /// Returns true if user needs to log in (defaults to true until authenticated).
  static Future<bool> getIsLoggin() async {
    final loggedIn = await getIsLoggedIn();
    return !loggedIn;
  }

  /// Sets isLoggedIn flag and synchronizes legacy isLoggin and isLoggOut flags.
  static Future<void> setIsLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, value);
    await prefs.setBool(keyIsLoggin, !value);
    await prefs.setBool(keyIsLogOut, !value);
  }

  /// Alias for backward compatibility (setting isLoggin=true means isLoggedIn=false).
  static Future<void> setIsLoggin(bool value) => setIsLoggedIn(!value);

  // ── Variable 3: role ───────────────────────────────────────────────────
  /// Returns user role string ('customer', 'service_provider', or 'admin').
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyRole);
    return AppRoles.canonicalize(raw);
  }

  /// Stores user role string.
  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final canonical = AppRoles.canonicalize(role) ?? role.toLowerCase().trim();
    await prefs.setString(keyRole, canonical);
  }

  // ── Modular Session Functions ──────────────────────────────────────────

  /// Called on successful Login or Sign Up:
  /// - [isFirstInstall] = false, [isFirstLoggin] = false
  /// - [isLoggedIn] = true, [isLoggin] = false, [isLoggOut] = false
  /// - [role] is persisted.
  static Future<void> setAuthSuccessSession({String role = AppRoles.customer}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsFirstInstall, false);
    await prefs.setBool(keyIsFirstLoggin, false);
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setBool(keyIsLoggin, false);
    await prefs.setBool(keyIsLogOut, false);
    final canonical = AppRoles.canonicalize(role) ?? role.toLowerCase().trim();
    await prefs.setString(keyRole, canonical);
  }

  /// Persists basic user profile details for offline restoration and snappy startup.
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String role = AppRoles.customer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUid, uid);
    await prefs.setString(keyUserName, name);
    await prefs.setString(keyUserEmail, email);
    await prefs.setString(keyUserPhone, phone);
    final canonical = AppRoles.canonicalize(role) ?? role.toLowerCase().trim();
    await prefs.setString(keyRole, canonical);
  }

  /// Retrieves cached user profile from SharedPreferences.
  static Future<Map<String, String>?> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(keyUid);
    if (uid == null || uid.isEmpty) return null;

    return {
      'uid': uid,
      'name': prefs.getString(keyUserName) ?? '',
      'email': prefs.getString(keyUserEmail) ?? '',
      'phone': prefs.getString(keyUserPhone) ?? '',
      'role': prefs.getString(keyRole) ?? 'customer',
    };
  }

  /// Clears cached user profile on logout.
  static Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUid);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserPhone);
  }

  /// Called on Logout from Profile page:
  /// - [isLoggedIn] = false, [isLoggin] = true, [isLoggOut] = true
  static Future<void> setLogoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.setBool(keyIsLoggin, true);
    await prefs.setBool(keyIsLogOut, true);
    await clearUserProfile();
  }

  /// Modular navigation check based on SharedPreferences variables.
  /// Follows the reference logic:
  /// 1. If [isLoggedIn] == true -> routes to role-specific screen (admin, provider, customer)
  /// 2. If [isFirstInstall] == true -> routes to [AppRoutes.getStarted]
  /// 3. Otherwise -> routes to [AppRoutes.login]
  static Future<void> checkUserStatusAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final bool isLoggedIn = prefs.getBool(keyIsLoggedIn) ??
        (!(prefs.getBool(keyIsLoggin) ?? true));
    final bool isFirstInstall = prefs.getBool(keyIsFirstInstall) ??
        prefs.getBool(keyIsFirstLoggin) ??
        true;
    final String? role = prefs.getString(keyRole)?.toLowerCase();

    if (!context.mounted) return;

    if (isLoggedIn) {
      if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
      } else if (role == 'provider' ||
          role == 'service_provider' ||
          role == 'service provider') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.providerDashboard);
      } else {
        // Customer / default user role
        Navigator.of(context).pushReplacementNamed(AppRoutes.customerDashboard);
      }
      return;
    }

    if (isFirstInstall) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.getStarted);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  /// Evaluates SharedPreferences variables and returns destination route string:
  /// 1. If [isLoggedIn] == true -> role-specific dashboard
  /// 2. Else if [isFirstInstall] / [isFirstLoggin] == true -> [AppRoutes.getStarted]
  /// 3. Else -> [AppRoutes.login]
  static Future<String> determineSplashTargetRoute() async {
    final loggedIn = await getIsLoggedIn();
    if (loggedIn) {
      final role = await getUserRole();
      if (role == 'admin') {
        return AppRoutes.adminDashboard;
      } else if (role == 'provider' ||
          role == 'service_provider' ||
          role == 'service provider') {
        return AppRoutes.providerDashboard;
      }
      return AppRoutes.customerDashboard;
    }

    final isFirst = await getIsFirstInstall();
    if (isFirst) {
      return AppRoutes.getStarted;
    }

    return AppRoutes.login;
  }

  // ── Backwards Compatibility Aliases ──────────────────────────────────
  static Future<void> setLoggedInSession([String role = 'customer']) =>
      setAuthSuccessSession(role: role);
  static Future<void> setLoggedOutSession() => setLogoutSession();
}
