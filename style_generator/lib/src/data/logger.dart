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

void cannotIgnorePositionalOrRequiredParameter(Variable variable, {required String clazz, required String method}) {
  warn(
    "Class '$clazz' parameter '${variable.type} ${variable.displayName}' cannot be excluded from $method because it is either a positional or required constructor parameter",
  );
}

void didNotFindLerpForParameter(Variable variable, {required String clazz}) {
  warn(
    "Class '$clazz' parameter '${variable.type} ${variable.displayName}' has no lerp method. Annotate the parameter with @StyleKey(lerp: noLerp) if this is intended",
  );
}
