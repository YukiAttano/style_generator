import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:style_generator/src/extensions/dart_object_extension.dart';

import 'style_key.dart';

class StyleKeyInternal<T> {
  final bool? inCopyWith;
  final bool? inMerge;
  final bool? inLerp;
  final String? lerp;

  const StyleKeyInternal({required bool? inCopyWith, required bool? inMerge, required bool? inLerp, required this.lerp})
    : inCopyWith = inCopyWith ?? true,
      inMerge = inMerge ?? true,
      inLerp = inLerp ?? true;

  Map<String, Object?> toJson() {
    return {"inCopyWith": inCopyWith, "inMerge": inMerge, "inLerp": inLerp, "lerp": lerp};
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
    inLerp: map["inLerp"]?.toValue() as bool?,
    inMerge: map["inMerge"]?.toValue() as bool?,
    inCopyWith: map["inCopyWith"]?.toValue() as bool?,
    lerp: callbackName,
  );
}
