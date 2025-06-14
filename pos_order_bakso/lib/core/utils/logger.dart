import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late Logger logger;

  factory AppLogger() => _instance;

  AppLogger._internal() {
    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.trace : Level.off,
    );
  }

  void t(String message) => logger.t(message);
  void d(String message) => logger.d(message);
  void i(String message) => logger.i(message);
  void w(String message) => logger.w(message);
  void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      logger.e(message, error: error, stackTrace: stackTrace);
}
