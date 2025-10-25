/// @docImport "package:style_generator_annotation/style_generator_annotation.dart";
library;

import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../extensions/dart_object_extension.dart";

/// The internal representation of [StyleKey]
///
/// [StyleKey] forces the [lerp] method to be be correctly typed,
/// while this internal representation just holds the function name.
class StyleKeyInternal<T> {
  final bool inCopyWith;
  final bool inMerge;
  final bool inLerp;
  final String? lerp;
  final String? merge;

  const StyleKeyInternal({
    required this.inCopyWith,
    required this.inMerge,
    required this.inLerp,
    required this.lerp,
    required this.merge,
  });

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
      "inMerge": inMerge,
      "inLerp": inLerp,
      "lerp": lerp,
      "merge": merge,
    };
  }
}

StyleKeyInternal<T> createStyleKey<T>(Map<String, DartObject?> map) {
  ExecutableElement? lerp = map["lerp"]?.toFunctionValue();
  ExecutableElement? merge = map["merge"]?.toFunctionValue();

  return StyleKeyInternal(
    inLerp: map["inLerp"]!.toValue()! as bool,
    inMerge: map["inMerge"]!.toValue()! as bool,
    inCopyWith: map["inCopyWith"]!.toValue()! as bool,
    lerp: _getFunctionName(lerp),
    merge: _getFunctionName(merge),
  );
}

String? _getFunctionName(ExecutableElement? function) {
  String? callbackName;
  if (function != null && function.isStatic) {
    switch (function.kind) {
      case ElementKind.METHOD:
        callbackName = "${function.enclosingElement?.displayName ?? ""}.${function.displayName}";
      case ElementKind.FUNCTION:
        callbackName = function.displayName;
    }
  }

  return callbackName;
}
