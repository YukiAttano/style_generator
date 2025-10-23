import "dart:async";

import "package:build/build.dart" as build;
import "package:logging/logging.dart";

import "variable.dart";

void log(
  Level level,
  Object? message, [
  Object? error,
  StackTrace? stackTrace,
  Zone? zone,
]) {
  build.log.log(
    level,
    message,
    error,
    stackTrace,
    zone,
  );
}

void info(Object? message) {
  log(Level.INFO, message);
}

void warn(Object? message) {
  log(Level.WARNING, message);
}

void cannotIgnorePositional(Variable variable, {required String clazz, required String method}) {
  warn(
      "Parameter '$variable' in Class $clazz cannot be excluded from $method because it is used as a positional constructor parameter");
}
