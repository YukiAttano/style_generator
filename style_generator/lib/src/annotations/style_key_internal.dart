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

  const StyleKeyInternal({
    required this.inCopyWith,
    required this.inMerge,
    required this.inLerp,
    required this.lerp,
  });

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
      "inMerge": inMerge,
      "inLerp": inLerp,
      "lerp": lerp,
    };
  }
}

StyleKeyInternal<T> createStyleKey<T>(Map<String, DartObject?> map) {
  ExecutableElement? lerp = map["lerp"]?.toFunctionValue();

  String? callbackName;
  if (lerp != null && lerp.isStatic) {
    switch (lerp.kind) {
      case ElementKind.METHOD:
        callbackName = "${lerp.enclosingElement?.displayName ?? ""}.${lerp.displayName}";
      case ElementKind.FUNCTION:
        callbackName = lerp.displayName;
    }
  }

  return StyleKeyInternal(
    inLerp: map["inLerp"]!.toValue()! as bool,
    inMerge: map["inMerge"]!.toValue()! as bool,
    inCopyWith: map["inCopyWith"]!.toValue()! as bool,
    lerp: callbackName,
  );
}
