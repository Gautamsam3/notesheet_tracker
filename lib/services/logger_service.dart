import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late Logger _logger;
  static const String _logTag = 'NotesheetTracker';

  Future<void> initialize() async {
    // Initialize flutter_logs only on supported platforms (not web)
    if (!kIsWeb) {
      try {
        await FlutterLogs.initLogs(
          logLevelsEnabled: [
            LogLevel.INFO,
            LogLevel.WARNING,
            LogLevel.ERROR,
            LogLevel.SEVERE
          ],
          timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
          directoryStructure: DirectoryStructure.FOR_DATE,
          logTypesEnabled: [_logTag],
          logFileExtension: LogFileExtension.LOG,
          logsWriteDirectoryName: "NotesheetTrackerLogs",
          logsExportDirectoryName: "NotesheetTrackerLogs/Exported",
          debugFileOperations: kDebugMode,
          isDebuggable: kDebugMode,
        );
      } catch (e) {
        // Fallback if flutter_logs fails to initialize
        debugPrint('Flutter logs initialization failed: $e');
      }
    }

    // Initialize logger with custom configuration
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        if (kDebugMode) DebugOutput(),
      ]),
    );

    info('🚀 Logger initialized successfully');
  }

  // Authentication specific logging
  void authInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('AUTH_INFO', message, error, stackTrace);
    _logger.i('🔐 AUTH: $message', error: error, stackTrace: stackTrace);
  }

  void authError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('AUTH_ERROR', message, error, stackTrace);
    _logger.e('🔐❌ AUTH ERROR: $message', error: error, stackTrace: stackTrace);
  }

  void authWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('AUTH_WARNING', message, error, stackTrace);
    _logger.w('🔐⚠️ AUTH WARNING: $message', error: error, stackTrace: stackTrace);
  }

  // Firestore specific logging
  void firestoreInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('FIRESTORE_INFO', message, error, stackTrace);
    _logger.i('🔥 FIRESTORE: $message', error: error, stackTrace: stackTrace);
  }

  void firestoreError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('FIRESTORE_ERROR', message, error, stackTrace);
    _logger.e('🔥❌ FIRESTORE ERROR: $message', error: error, stackTrace: stackTrace);
  }

  // UI specific logging
  void uiInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('UI_INFO', message, error, stackTrace);
    _logger.i('🖥️ UI: $message', error: error, stackTrace: stackTrace);
  }

  void uiError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('UI_ERROR', message, error, stackTrace);
    _logger.e('🖥️❌ UI ERROR: $message', error: error, stackTrace: stackTrace);
  }

  // General logging methods
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('DEBUG', message, error, stackTrace);
    _logger.d('🐛 $message', error: error, stackTrace: stackTrace);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('INFO', message, error, stackTrace);
    _logger.i('ℹ️ $message', error: error, stackTrace: stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('WARNING', message, error, stackTrace);
    _logger.w('⚠️ $message', error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('ERROR', message, error, stackTrace);
    _logger.e('❌ $message', error: error, stackTrace: stackTrace);
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logToFile('FATAL', message, error, stackTrace);
    _logger.f('💀 FATAL: $message', error: error, stackTrace: stackTrace);
  }

  // Log user actions for analytics
  void userAction(String action, Map<String, dynamic>? parameters) {
    final message = 'User Action: $action';
    final logData = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': parameters,
    };
    
    _logToFile('USER_ACTION', message, logData, null);
    _logger.i('👤 $message', error: logData);
  }

  // Performance logging
  void performance(String operation, Duration duration, [Map<String, dynamic>? metadata]) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    final logData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata,
    };
    
    _logToFile('PERFORMANCE', message, logData, null);
    _logger.i('⚡ $message', error: logData);
  }

  // Network logging
  void network(String method, String url, int? statusCode, [Map<String, dynamic>? data]) {
    final message = 'Network: $method $url (${statusCode ?? 'pending'})';
    final logData = {
      'method': method,
      'url': url,
      'status_code': statusCode,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    
    _logToFile('NETWORK', message, logData, null);
    _logger.i('🌐 $message', error: logData);
  }

  // Private method to log to file
  void _logToFile(String level, String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode && !kIsWeb) {
      try {
        final logMessage = error != null 
            ? '$message | Error: $error${stackTrace != null ? ' | Stack: $stackTrace' : ''}'
            : message;
        
        switch (level.toUpperCase()) {
          case 'INFO':
          case 'AUTH_INFO':
          case 'FIRESTORE_INFO':
          case 'UI_INFO':
          case 'DEBUG':
          case 'USER_ACTION':
          case 'PERFORMANCE':
          case 'NETWORK':
            FlutterLogs.logInfo(_logTag, 'INFO', logMessage);
            break;
          case 'WARNING':
          case 'AUTH_WARNING':
            FlutterLogs.logWarn(_logTag, 'WARNING', logMessage);
            break;
          case 'ERROR':
          case 'AUTH_ERROR':
          case 'FIRESTORE_ERROR':
          case 'UI_ERROR':
            FlutterLogs.logError(_logTag, 'ERROR', logMessage);
            break;
          case 'FATAL':
            FlutterLogs.logError(_logTag, 'FATAL', logMessage);
            break;
        }
      } catch (e) {
        // Fallback to debug print if flutter_logs fails
        debugPrint('$level: $message${error != null ? ' | Error: $error' : ''}');
      }
    }
  }

  // Export logs for debugging
  Future<String?> exportLogs() async {
    if (kIsWeb) {
      const message = 'Log export not available on web platform';
      info(message);
      return message;
    }
    
    try {
      await FlutterLogs.exportLogs(
        exportType: ExportType.ALL,
      );
      const exportedPath = 'Logs exported successfully';
      info(exportedPath);
      return exportedPath;
    } catch (e, stackTrace) {
      error('Failed to export logs', e, stackTrace);
      return null;
    }
  }

  // Clear logs
  Future<void> clearLogs() async {
    if (kIsWeb) {
      info('Log clearing not available on web platform');
      return;
    }
    
    try {
      await FlutterLogs.clearLogs();
      info('Logs cleared successfully');
    } catch (e, stackTrace) {
      error('Failed to clear logs', e, stackTrace);
    }
  }

  // Print all available logs for debugging
  Future<void> printAllLogs() async {
    try {
      info('Printing all available logs...');
      // Since getLogFileNames is not available, we'll just note this
      info('Log files are stored in the app\'s document directory');
    } catch (e, stackTrace) {
      error('Failed to print logs', e, stackTrace);
    }
  }
}

// Custom output for DevTools
class DebugOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (kDebugMode) {
      for (var line in event.lines) {
        debugPrint(line);
      }
    }
  }
}
