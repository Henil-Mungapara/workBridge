import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Lightweight logger for WORKBRIDGE.
///
/// Logs are emitted only in debug mode — production builds are silent.
/// Usage:
/// ```dart
/// AppLogger.info('User signed in', tag: 'Auth');
/// AppLogger.error('Fetch failed', error: e, stackTrace: st);
/// ```
abstract final class AppLogger {
  static const String _defaultTag = 'WorkBridge';

  /// Informational log.
  static void info(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      dev.log('ℹ️ $message', name: tag);
    }
  }

  /// Warning log.
  static void warning(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      dev.log('⚠️ $message', name: tag);
    }
  }

  /// Error log with optional error object and stack trace.
  static void error(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        '❌ $message',
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
