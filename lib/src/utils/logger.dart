import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger('KCManagement');
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // In development, use debugPrint which is safe for production
      if (kDebugMode) {
        debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      }
      // In production, this could be modified to use a proper logging service
    });
    
    _initialized = true;
  }

  static void info(String message) {
    _logger.info(message);
  }

  static void warning(String message) {
    _logger.warning(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  static void debug(String message) {
    _logger.fine(message);
  }
} 