/// User-friendly exception wrapper for WORKBRIDGE.
///
/// Maps raw Firebase/platform exceptions to messages safe to show in the UI.
/// Technical details are preserved in [code] for logging/debugging.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// Human-readable message suitable for display in UI.
  final String message;

  /// Raw error code for debugging (e.g., 'permission-denied').
  final String? code;

  @override
  String toString() => 'AppException($code): $message';

  // ── Firebase Auth ────────────────────────────────────────────────────
  /// Maps FirebaseAuthException codes to user-friendly messages.
  static AppException fromAuthCode(String code) {
    return switch (code) {
      'user-not-found'            => const AppException('No account found with this email.', code: 'user-not-found'),
      'wrong-password'            => const AppException('Incorrect password. Please try again.', code: 'wrong-password'),
      'invalid-credential'        => const AppException('Invalid email or password.', code: 'invalid-credential'),
      'email-already-in-use'      => const AppException('An account already exists with this email.', code: 'email-already-in-use'),
      'weak-password'             => const AppException('Password is too weak. Use at least 8 characters.', code: 'weak-password'),
      'invalid-email'             => const AppException('Please enter a valid email address.', code: 'invalid-email'),
      'user-disabled'             => const AppException('This account has been disabled. Contact support.', code: 'user-disabled'),
      'too-many-requests'         => const AppException('Too many attempts. Please try again later.', code: 'too-many-requests'),
      'operation-not-allowed'     => const AppException('This sign-in method is not enabled.', code: 'operation-not-allowed'),
      'network-request-failed'    => const AppException('Network error. Check your internet connection.', code: 'network-request-failed'),
      _                           => AppException('Something went wrong. Please try again.', code: code),
    };
  }

  // ── Firestore ────────────────────────────────────────────────────────
  /// Maps Firestore error codes to user-friendly messages.
  static AppException fromFirestoreCode(String code) {
    return switch (code) {
      'permission-denied'    => const AppException("You don't have permission to perform this action.", code: 'permission-denied'),
      'not-found'            => const AppException('The requested data was not found.', code: 'not-found'),
      'already-exists'       => const AppException('This record already exists.', code: 'already-exists'),
      'resource-exhausted'   => const AppException('Too many requests. Please wait and try again.', code: 'resource-exhausted'),
      'unavailable'          => const AppException('Service temporarily unavailable. Try again later.', code: 'unavailable'),
      'cancelled'            => const AppException('The operation was cancelled.', code: 'cancelled'),
      _                      => AppException('Something went wrong. Please try again.', code: code),
    };
  }

  // ── Generic fallback ─────────────────────────────────────────────────
  /// Wraps any unknown exception with a safe message.
  static AppException fromException(Object error) {
    return AppException(
      'An unexpected error occurred. Please try again.',
      code: error.runtimeType.toString(),
    );
  }
}

/// Exception thrown when a user's account role is unrecognized, misspelled, or unauthorized.
/// WorkBridge strictly recognizes only three roles: Customer, Service_Provider, and Admin.
class AppRoleException extends AppException {
  /// The unrecognized role string retrieved from the database.
  final String? attemptedRole;

  const AppRoleException({
    required String message,
    this.attemptedRole,
    String? code = 'unrecognized-role',
  }) : super(message, code: code);

  @override
  String toString() => message;
}

