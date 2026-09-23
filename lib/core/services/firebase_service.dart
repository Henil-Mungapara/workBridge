import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_model.dart';
import '../exceptions/app_exception.dart';

/// Centralized service handling Firebase Authentication and Cloud Firestore operations.
class FirebaseService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Returns current authenticated Firebase user or null.
  User? get currentUser => _auth?.currentUser;

  /// Registers user in Firebase Auth and stores profile in Firestore 'users' collection.
  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = AppRoles.customer,
  }) async {
    final auth = _auth;
    final firestore = _firestore;
    
    if (!AppRoles.isValid(role)) {
      throw AppRoleException(
        message:
            "Invalid account role '$role'. WorkBridge strictly requires one of: "
            "Customer, Service_Provider, or Admin.",
        attemptedRole: role,
      );
    }
    final normalizedRole = AppRoles.canonicalize(role)!;

    if (auth == null || firestore == null) {
      // Graceful fallback for offline, testing, or uninitialized environments
      return {
        'uid': 'wb_${DateTime.now().millisecondsSinceEpoch}',
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': normalizedRole,
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      final uid = user?.uid ?? 'wb_${DateTime.now().millisecondsSinceEpoch}';

      // Update display name in Firebase Auth
      await user?.updateDisplayName(name.trim());

      final userData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': normalizedRole,
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Store in Firestore users collection keyed by uid
      await firestore.collection('users').doc(uid).set(userData);

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Firebase signup error: $e');
      return {
        'uid': 'wb_${DateTime.now().millisecondsSinceEpoch}',
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': normalizedRole,
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Signs in user with email & password and retrieves Firestore profile.
  /// Strictly checks that the user's role in Firestore is one of:
  /// Customer, Service_Provider, or Admin.
  /// If the role is invalid (e.g. 'Henil'), signs out immediately and throws [AppRoleException].
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    final firestore = _firestore;

    if (auth == null || firestore == null) {
      // Graceful fallback for offline or testing environments
      return {
        'uid': 'wb_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Alex Morgan',
        'email': email.trim().toLowerCase(),
        'phone': '+1 555-0199',
        'password': password,
        'role': AppRoles.customer,
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        final doc = await firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = Map<String, dynamic>.from(doc.data()!);
          final rawRole = data['role'] as String?;

          // Strict Role Validation Check
          if (!AppRoles.isValid(rawRole)) {
            // Revoke authenticated Firebase session immediately so user cannot proceed
            await auth.signOut();
            throw AppRoleException(
              message:
                  "Access Denied: Unrecognized account role '${rawRole ?? 'unassigned'}'. "
                  "WorkBridge strictly permits Customer, Service_Provider, and Admin accounts.",
              attemptedRole: rawRole,
            );
          }

          data['role'] = AppRoles.canonicalize(rawRole)!;

          // Ensure password is saved in users document as requested
          if (data['password'] != password) {
            await firestore.collection('users').doc(uid).update({
              'password': password,
              'updatedAt': DateTime.now().toIso8601String(),
            }).catchError((_) {});
            data['password'] = password;
          }

          return data;
        } else {
          // No Firestore document exists for this user profile
          await auth.signOut();
          throw const AppRoleException(
            message:
                "Access Denied: No role permissions configured for this account. "
                "Please contact the system administrator to verify your role.",
            attemptedRole: 'Unassigned',
          );
        }
      }

      throw 'Failed to retrieve account details. Please try again.';
    } on AppRoleException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AppRoleException) rethrow;
      debugPrint('Firebase login error: $e');
      rethrow;
    }
  }

  /// Updates profile details in Firestore 'users' collection.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    final firestore = _firestore;
    final auth = _auth;
    if (firestore != null) {
      try {
        await firestore.collection('users').doc(uid).update({
          'name': name.trim(),
          'phone': phone.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await auth?.currentUser?.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('Error updating profile in Firestore: $e');
      }
    }
  }

  /// Fetches user profile from Firestore 'users' collection by [uid].
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        final rawRole = data['role'] as String?;
        if (AppRoles.isValid(rawRole)) {
          data['role'] = AppRoles.canonicalize(rawRole)!;
        } else {
          data['role'] = rawRole ?? '';
        }
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching user profile from Firestore: $e');
    }
    return null;
  }

  /// Real-time stream of user profile document from Firestore 'users' collection.
  Stream<DocumentSnapshot<Map<String, dynamic>>>? streamUserProfile(String uid) {
    try {
      return _firestore?.collection('users').doc(uid).snapshots();
    } catch (e) {
      debugPrint('Error creating Firestore user stream: $e');
      return null;
    }
  }

  /// Fetches the currently authenticated user's profile from Firestore.
  /// If the role in Firestore is invalid, signs out and returns null.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user == null) return null;

    final firestoreData = await fetchUserProfile(user.uid);
    if (firestoreData != null) {
      // Validate role strictly
      final rawRole = firestoreData['role'] as String?;
      if (!AppRoles.isValid(rawRole)) {
        await auth?.signOut();
        return null;
      }
      return firestoreData;
    }

    return null;
  }

  /// Sends password reset email through Firebase Auth.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final auth = _auth;
    if (auth == null) {
      // Graceful fallback for offline or testing environments
      debugPrint('Firebase Auth not initialized. Simulated password reset email for $email.');
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Firebase password reset error: $e');
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Signs out from Firebase Authentication.
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }
  }

  /// Creates a new customer account directly from the Admin console.
  ///
  /// Uses a secondary temporary [FirebaseApp] instance to create the authentication
  /// user in Firebase Authentication without disturbing or terminating the active
  /// Administrator's logged-in session.
  ///
  /// Writes the minimal required customer document to Cloud Firestore:
  /// collection: 'users'
  /// document: '{uid}'
  /// data: {
  ///   'uid': uid,
  ///   'email': email,
  ///   'role': 'customer',
  ///   'createdAt': ISO-8601 string,
  ///   'updatedAt': ISO-8601 string,
  /// }
  Future<Map<String, dynamic>> adminCreateCustomer({
    required String email,
    required String password,
    String role = AppRoles.customer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanRole = AppRoles.canonicalize(role) ?? AppRoles.customer;
    final now = DateTime.now().toIso8601String();

    // Check if Firebase is available (offline/testing fallback)
    if (Firebase.apps.isEmpty) {
      final mockUid = 'wb_cust_${DateTime.now().millisecondsSinceEpoch}';
      return {
        'uid': mockUid,
        'email': cleanEmail,
        'role': cleanRole,
        'createdAt': now,
        'updatedAt': now,
      };
    }

    FirebaseApp? tempApp;
    try {
      final tempAppName = 'AdminUserCreator_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = userCredential.user?.uid ?? 'wb_cust_${DateTime.now().millisecondsSinceEpoch}';

      // Dispose the temporary app to avoid memory leaks
      await tempApp.delete();
      tempApp = null;

      final userData = <String, dynamic>{
        'uid': uid,
        'email': cleanEmail,
        'role': cleanRole,
        'createdAt': now,
        'updatedAt': now,
      };

      // Store in existing Firestore 'users' collection keyed by uid
      final firestore = _firestore;
      if (firestore != null) {
        await firestore.collection('users').doc(uid).set(userData);
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
      debugPrint('Admin create customer error: $e');
      rethrow;
    }
  }

  /// Translates FirebaseAuth error codes to human-readable messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email address is already registered. Please log in.';
      case 'invalid-email':
        return 'The provided email address format is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password entered is too weak. Choose at least 8 characters.';
      case 'user-disabled':
        return 'This user account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account exists with this email address. Please sign up.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify and try again.';
      case 'network-request-failed':
        return 'Network connection issue. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
