import "dart:async";

import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/type.dart";
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

void styleKeyTypeMismatch(Variable variable, DartType? styleKey) {
  warn(
    "Type mismatch between '${variable.type} ${variable.displayName}' and '$styleKey' annotation",
  );
}

void typeIsNotSubtypeOfInterfaceType(DartType type) {
  warn("Type ${type.getDisplayString()} is not an interface type (e.g class, interface)");
}

void typeHasNoTypeArguments(DartType type) {
  warn("$type has no type arguments (e.g. is not typed like Some<Type1, Type2, ...> ");
}

void hasNoType(DartObject obj) {
  warn("$obj has no corresponding type");
}
