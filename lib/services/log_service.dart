import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Uygulama genelinde kullanılacak loglama servisi
class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  /// Debug seviyesinde log
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info seviyesinde log
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning seviyesinde log
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error seviyesinde log (ayrıca Firebase'e de kaydedilir)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // Her zaman Firebase'e kaydet (test için)
    _logToFirebase(
      level: 'ERROR',
      message: message,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Fatal seviyesinde log (uygulama çökmesi)
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    
    // Her zaman Firebase'e kaydet
    _logToFirebase(
      level: 'FATAL',
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Firebase'e log kaydet
  static Future<void> _logToFirebase({
    required String level,
    required String message,
    String? error,
    String? stackTrace,
  }) async {
    try {
      final user = FirebaseService.currentUser;
      await FirebaseService.firestore.collection('app_logs').add({
        'level': level,
        'message': message,
        'error': error,
        'stackTrace': stackTrace,
        'userId': user?.uid,
        'userEmail': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        'appVersion': '1.0.0', // Versiyonu buradan alabilirsiniz
      });
    } catch (e) {
      // Firebase'e log kaydederken hata olursa sessizce geç
      debugPrint('Firebase log error: $e');
    }
  }

  /// User action log (kullanıcı davranışlarını takip için)
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User Action: $action${data != null ? ' - Data: $data' : ''}');
    
    // Her zaman Firebase'e kaydet (test için)
    _logUserActionToFirebase(action, data);
  }

  /// Firebase'e kullanıcı eylemi kaydet
  static Future<void> _logUserActionToFirebase(String action, Map<String, dynamic>? data) async {
    try {
      final user = FirebaseService.currentUser;
      await FirebaseService.firestore.collection('user_actions').add({
        'action': action,
        'data': data,
        'userId': user?.uid,
        'userEmail': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        'appVersion': '1.0.0',
      });
    } catch (e) {
      debugPrint('Firebase user action log error: $e');
    }
  }

  /// API çağrıları için log
  static void logApiCall(String endpoint, {String? method, dynamic response, dynamic error}) {
    if (error != null) {
      LogService.error('API Error: $method $endpoint', error);
    } else {
      LogService.debug('API Success: $method $endpoint');
    }
  }

  /// Navigation log
  static void logNavigation(String from, String to) {
    debug('Navigation: $from -> $to');
  }
}

