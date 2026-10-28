// Registro de eventos de la app. En modo depuración se ve en la consola de Android Studio
// (pestaña Run / Logcat); en la versión publicada solo se guardan advertencias y errores.
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime at;
  final LogLevel level;
  final String tag;
  final String message;
  const LogEntry(this.at, this.level, this.tag, this.message);

  @override
  String toString() => '${at.toIso8601String().substring(11, 19)} ${level.name.toUpperCase()} [$tag] $message';
}

class AppLogger {
  AppLogger._();

  static const _max = 200;
  static final List<LogEntry> _recent = [];

  /// Últimos registros (útil para mostrar en una pantalla de diagnóstico).
  static List<LogEntry> get recent => List.unmodifiable(_recent);

  static void d(String message, {String tag = 'App'}) => _log(LogLevel.debug, tag, message);
  static void i(String message, {String tag = 'App'}) => _log(LogLevel.info, tag, message);
  static void w(String message, {String tag = 'App'}) => _log(LogLevel.warning, tag, message);
  static void e(String message, {String tag = 'App', Object? error, StackTrace? stack}) =>
      _log(LogLevel.error, tag, error == null ? message : '$message · $error', stack: stack);

  static void _log(LogLevel level, String tag, String message, {StackTrace? stack}) {
    if (!kDebugMode && (level == LogLevel.debug || level == LogLevel.info)) return;
    final entry = LogEntry(DateTime.now(), level, tag, message);
    _recent.add(entry);
    if (_recent.length > _max) _recent.removeAt(0);
    developer.log(message, name: 'CafeDirecto.$tag', level: _levelValue(level), stackTrace: stack);
  }

  static int _levelValue(LogLevel l) => switch (l) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}
