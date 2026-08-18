import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('DEBUG: $message');
      if (error != null) print('ERROR: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('ERROR: $message');
    if (error != null) print('DETAILS: $error');
    if (stackTrace != null) print(stackTrace);
  }

  static void info(String message) {
    print('INFO: $message');
  }
}
