import "dart:async";
import "dart:developer" as dev;

import "package:logging/logging.dart" ;

import "variable.dart";

void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = "",
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  print(
    message,

  );
}

void warn(String message) {
  log(message, level: Level.WARNING.value);
}

void cannotIgnorePositional(Variable variable, {required String clazz, required String method}) {
  warn("Parameter '$variable' in Class $clazz cannot be excluded from $method because it is used as a positional constructor parameter");
}
