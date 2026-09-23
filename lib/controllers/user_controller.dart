import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import '../core/exceptions/app_exception.dart';
import '../core/services/app_preferences.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_helper.dart';
import '../models/user_model.dart';

/// Controller handling user business logic, state mutation, and Firebase synchronization.
///
/// Manages user state dynamically using [Provider]. Any modification to the user profile
/// (e.g. editing name or phone) immediately mutates local state, notifies all listening
/// widgets across the entire app, and synchronizes with Cloud Firestore.
/// Also subscribes to real-time Firestore snapshots so changes made anywhere in the database
/// automatically propagate to the UI via [notifyListeners].
class UserController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel _user = UserModel.empty();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStreamSubscription;
  String? _sessionRole;

  bool _isLoggedIn = false;
  bool _termsAccepted = false;

  // ── Getters ─────────────────────────────────────────────────────────────
  UserModel get user => _user;
  String get uid => _user.uid;
  String get userName => _user.name;
  String get email => _user.email;
  String get phone => _user.phone;
  String get role => _user.role;
  List<String> get userCategories => _user.categories;
  String get createdAt => _user.createdAt;
  String? get sessionRole => _sessionRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get termsAccepted => _termsAccepted;

  // ── Business Actions ───────────────────────────────────────────────────

  /// Restores authorized user session dynamically from Firebase (or cached storage).
  /// Returns true if an active authenticated user session with a VALID role
  /// (Customer, Service_Provider, or Admin) is successfully restored.
  Future<bool> restoreUserSession() async {
    try {
      final isLoggedInPref = await AppPreferences.getIsLoggedIn();
      final currentFirebaseUser = _firebaseService.currentUser;

      if (!isLoggedInPref && currentFirebaseUser == null) {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }

      // 1. Check local cached user profile
      final cached = await AppPreferences.getCachedUserProfile();
      if (cached != null && cached['uid'] != null && cached['uid']!.isNotEmpty) {
        final cachedRole = cached['role'];
        if (!AppRoles.isValid(cachedRole)) {
          // If cached role is invalid, revoke immediately
          await logout();
          return false;
        }
        _user = UserModel(
          uid: cached['uid']!,
          name: cached['name'] ?? '',
          email: cached['email'] ?? '',
          phone: cached['phone'] ?? '',
          role: AppRoles.canonicalize(cachedRole)!,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        _sessionRole = _user.role;
        _isLoggedIn = true;
        notifyListeners();
        _listenToUserProfile(_user.uid);
      }

      // 2. Dynamically fetch the live profile from Firebase (Firestore / Auth)
      final liveUserData = await _firebaseService.getCurrentUserProfile();
      if (liveUserData != null) {
        final parsedUser = UserModel.fromMap(liveUserData);
        if (!parsedUser.hasValidRole) {
          // Unrecognized role in Firestore; revoke session
          await logout();
          return false;
        }
        _user = parsedUser;
        _sessionRole = _user.role;
        _isLoggedIn = true;
        await AppPreferences.saveUserProfile(
          uid: _user.uid,
          name: _user.name,
          email: _user.email,
          phone: _user.phone,
          role: _user.role,
        );
        await AppPreferences.setUserRole(_user.role);
        notifyListeners();
        _listenToUserProfile(_user.uid);
        return true;
      } else if (cached != null) {
        final prefRole = await AppPreferences.getUserRole();
        if (prefRole != null && prefRole.isNotEmpty && AppRoles.isValid(prefRole)) {
          _user = _user.copyWith(role: AppRoles.canonicalize(prefRole)!);
          _sessionRole = _user.role;
          _isLoggedIn = true;
          notifyListeners();
          return true;
        }
      }

      _isLoggedIn = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error restoring user session: $e');
      return _isLoggedIn;
    }
  }

  /// Listens to real-time Firestore database snapshot updates for [uid].
  /// If an Admin updates this user's role remotely in Firestore, automatically
  /// revokes active session, logs out, and redirects to Login with an alert.
  void _listenToUserProfile(String uid) {
    if (uid.isEmpty) return;
    _userStreamSubscription?.cancel();
    _userStreamSubscription = _firebaseService.streamUserProfile(uid)?.listen(
      (snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final parsed = UserModel.fromMap(data, snapshot.id);
          
          if (!parsed.hasValidRole) {
            // Unrecognized/invalid role assigned in database
            await logout();
            _triggerAutoLogoutRedirect(
              "Access Denied: Your account role was modified to an unrecognized value ('${parsed.role}'). Session closed.",
            );
            return;
          }

          // Detect if user's role was changed by an Admin while active
          if (_sessionRole != null &&
              _sessionRole!.isNotEmpty &&
              parsed.canonicalRole != AppRoles.canonicalize(_sessionRole)) {
            final oldDisplay = AppRoles.displayName(_sessionRole);
            final newDisplay = AppRoles.displayName(parsed.role);
            debugPrint('Live role change detected: from $_sessionRole to ${parsed.role}. Auto logging out.');

            await logout();
            _triggerAutoLogoutRedirect(
              'Your role has been changed from $oldDisplay to $newDisplay by the administrator. Your active session has been closed. Please log in again to access your new portal.',
            );
            return;
          }

          _user = parsed;
          _sessionRole = parsed.role;
          await AppPreferences.saveUserProfile(
            uid: _user.uid,
            name: _user.name,
            email: _user.email,
            phone: _user.phone,
            role: _user.role,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Real-time Firestore user stream error: $error');
      },
    );
  }

  /// Closes active panel and redirects to login view when role change is detected.
  void _triggerAutoLogoutRedirect(String message) {
    final nav = AppRoutes.navigatorKey.currentState;
    final context = AppRoutes.navigatorKey.currentContext;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      if (context != null) {
        UiHelper.showSnackBar(context, message, isError: true);
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Role Updated', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Log In Again'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Synchronizes controller state with persistent SharedPreferences session.
  void syncSessionState({required bool isLoggedIn, String? role}) {
    _isLoggedIn = isLoggedIn;
    if (role != null && role.isNotEmpty) {
      _user = _user.copyWith(role: role);
    }
    notifyListeners();
  }

  /// Updates profile name across Controller, Firestore, and listeners.
  void updateProfileName(String newName) {
    if (newName.trim().isNotEmpty && newName.trim() != _user.name) {
      _user = _user.copyWith(name: newName.trim());
      notifyListeners(); // Immediate local UI update across all Provider watchers
      _firebaseService.updateUserProfile(
        uid: _user.uid,
        name: _user.name,
        phone: _user.phone,
      );
      AppPreferences.saveUserProfile(
        uid: _user.uid,
        name: _user.name,
        email: _user.email,
        phone: _user.phone,
        role: _user.role,
      );
    }
  }

  /// Updates profile name and phone across Controller and Firestore.
  /// Notifies all Provider listeners immediately so every screen displaying
  /// the user's name re-renders in real-time.
  Future<void> updateProfile({required String name, required String phone}) async {
    _user = _user.copyWith(name: name.trim(), phone: phone.trim());
    notifyListeners(); // Immediate zero-latency UI update across all active panels

    await _firebaseService.updateUserProfile(
      uid: _user.uid,
      name: _user.name,
      phone: _user.phone,
    );
    await AppPreferences.saveUserProfile(
      uid: _user.uid,
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      role: _user.role,
    );
    notifyListeners();
  }

  /// Updates provider's assigned categories across Controller and Firestore.
  Future<void> updateCategories(List<String> categories) async {
    _user = _user.copyWith(categories: categories);
    notifyListeners();

    try {
      if (_user.uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(_user.uid).update({
          'categories': categories,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error updating categories in Firestore: $e');
    }
  }

  /// Sets policy agreement status.
  void setTermsAccepted(bool accepted) {
    if (_termsAccepted != accepted) {
      _termsAccepted = accepted;
      notifyListeners();
    }
  }

  /// Registers user in Firebase Auth and stores profile in Firestore users collection.
  Future<void> signUpWithFirebase({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = AppRoles.customer,
  }) async {
    final userData = await _firebaseService.signUpWithEmail(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );

    final parsedUser = UserModel.fromMap(userData);
    if (!parsedUser.hasValidRole) {
      await _firebaseService.signOut();
      throw AppRoleException(
        message:
            "Invalid role '${parsedUser.role}'. Only Customer, Service_Provider, and Admin are authorized.",
        attemptedRole: parsedUser.role,
      );
    }

    _user = parsedUser;
    _sessionRole = _user.role;
    _isLoggedIn = true;

    await AppPreferences.setLoggedInSession(_user.role);
    await AppPreferences.saveUserProfile(
      uid: _user.uid,
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      role: _user.role,
    );
    notifyListeners();
    _listenToUserProfile(_user.uid);
  }

  /// Authenticates user in Firebase Auth and retrieves Firestore user document.
  /// Strictly rejects any account where the role in Firestore is not recognized.
  Future<void> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    final userData = await _firebaseService.signInWithEmail(
      email: email,
      password: password,
    );

    final parsedUser = UserModel.fromMap(userData);
    if (!parsedUser.hasValidRole) {
      await _firebaseService.signOut();
      throw AppRoleException(
        message:
            "Access Denied: Unrecognized account role '${parsedUser.role}'. "
            "Only Customer, Service_Provider, and Admin are authorized.",
        attemptedRole: parsedUser.role,
      );
    }

    _user = parsedUser;
    _sessionRole = _user.role;
    _isLoggedIn = true;

    await AppPreferences.setLoggedInSession(_user.role);
    await AppPreferences.saveUserProfile(
      uid: _user.uid,
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      role: _user.role,
    );
    notifyListeners();
    _listenToUserProfile(_user.uid);
  }

  /// Synchronous fallback sign-up helper.
  void signUp({
    required String name,
    required String email,
    required String phone,
    String? uid,
    String role = 'customer',
  }) {
    _user = UserModel(
      uid: uid ?? 'wb_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _sessionRole = _user.role;
    _isLoggedIn = true;
    AppPreferences.setLoggedInSession(_user.role);
    AppPreferences.saveUserProfile(
      uid: _user.uid,
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      role: _user.role,
    );
    notifyListeners();
  }

  /// Synchronous fallback login helper.
  void login({
    required String email,
    required String password,
    String? name,
    String? uid,
  }) {
    _user = _user.copyWith(
      email: email.trim(),
      name: name?.trim(),
      uid: uid,
    );
    _sessionRole = _user.role;
    _isLoggedIn = true;
    AppPreferences.setLoggedInSession(_user.role);
    AppPreferences.saveUserProfile(
      uid: _user.uid,
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      role: _user.role,
    );
    notifyListeners();
  }

  /// Sends password reset email via Firebase Auth.
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseService.sendPasswordResetEmail(email: email);
  }

  /// Signs out user, marks session logged out, and clears state.
  Future<void> logout() async {
    await _userStreamSubscription?.cancel();
    _userStreamSubscription = null;
    await _firebaseService.signOut();
    await AppPreferences.setLoggedOutSession();
    _user = UserModel.empty();
    _sessionRole = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}

/// Provider alias for backward compatibility.
typedef UserProvider = UserController;
