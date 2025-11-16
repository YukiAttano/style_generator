/// @docImport "package:style_generator_annotation/style_generator_annotation.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../data/ast_visitor/annotation_parameter_lookup_visitor.dart";
import "../data/logger.dart";
import "../extensions/dart_object_extension.dart";

/// The internal representation of [StyleKey]
///
/// [StyleKey] forces the [lerp] method to be be correctly typed,
/// while this internal representation just holds the function name.
class StyleKeyInternal<T> {
  static const String srcAnnotationName = "StyleKey";
  static const String inCopyWithName = "inCopyWith";
  static const String inMergeName = "inMerge";
  static const String inLerpName = "inLerp";
  static const String lerpName = "lerp";
  static const String mergeName = "merge";

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
      inCopyWithName: inCopyWith,
      inMergeName: inMerge,
      inLerpName: inLerp,
      lerpName: lerp,
      mergeName: merge,
    };
  }
}

StyleKeyInternal<T> createStyleKey<T>(ResolvedLibraryResult resolved, Map<String, DartObject?> map) {
  const String styleKeyName = StyleKeyInternal.srcAnnotationName;
  const String lerpName = StyleKeyInternal.lerpName;
  const String mergeName = StyleKeyInternal.mergeName;

  ExecutableElement? lerp = map[lerpName]?.toFunctionValue();
  ExecutableElement? merge = map[mergeName]?.toFunctionValue();

  AnnotationParameterLookupVisitor lerpLookup =
      AnnotationParameterLookupVisitor(parameterName: lerpName, element: lerp);

  AnnotationParameterLookupVisitor mergeLookup =
      AnnotationParameterLookupVisitor(parameterName: mergeName, element: merge);

  lerpLookup.run(resolved.units);
  mergeLookup.run(resolved.units);

  String? lerpFunction = lerpLookup.result;
  String? mergeFunction = mergeLookup.result;

  if (lerp != null && lerpFunction == null) {
    couldNotResolveFunction(lerpName, lerp.toString(), styleKeyName);
    lerpFunction = _getFunctionName(lerp);
  }
  if (merge != null && mergeFunction == null) {
    couldNotResolveFunction(mergeName, merge.toString(), styleKeyName);
    mergeFunction = _getFunctionName(merge);
  }

  return StyleKeyInternal(
    inLerp: map[StyleKeyInternal.inLerpName]!.toValue()! as bool,
    inMerge: map[StyleKeyInternal.inMergeName]!.toValue()! as bool,
    inCopyWith: map[StyleKeyInternal.inCopyWithName]!.toValue()! as bool,
    lerp: lerpFunction,
    merge: mergeFunction,
  );
}

/// Fallback name lookup if AST lookup fails
///
/// Due to the nature of [Element]s, this method does not recognize prefix name imports
/// (Hence why we search the AST).
///
/// The AST lookup should always work and
/// this function exists solely to have a generalized backup
String? _getFunctionName(ExecutableElement? function) {
  String? callbackName;
  if (function != null) {
    if (function.isStatic) {
      switch (function.kind) {
        case ElementKind.METHOD:
          callbackName = "${function.enclosingElement?.displayName ?? ""}.${function.displayName}";
        case ElementKind.FUNCTION:
          callbackName = function.displayName;
      }
    } else {
      switch (function.kind) {
        case ElementKind.CONSTRUCTOR:
          callbackName = function.displayName;
      }
    }
  }

  return callbackName;
}
