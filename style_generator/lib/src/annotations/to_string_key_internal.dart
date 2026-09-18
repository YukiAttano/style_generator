/// @docImport "package:style_generator_annotation/to_string_generator_annotation.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:meta/meta.dart";

import "../data/ast_visitor/annotation_parameter_lookup_visitor.dart";
import "../data/logger.dart";
import "../extensions/dart_object_extension.dart";
import "../extensions/element/executable_element_extension.dart";

/// The internal representation of [ToStringKey]
class ToStringKeyInternal<T> {
  static const String srcAnnotationName = "ToStringKey";
  static const String inToStringName = "inToString";
  static const String stringifyName = "stringify";

  final bool inToString;
  final String? stringify;

  const ToStringKeyInternal({
    required this.inToString,
    required this.stringify,
  });

  /// These defaults must be the same as the one set by [ToStringKey]
  @internal
  static const ToStringKeyInternal defaults = ToStringKeyInternal(
    inToString: true,
    stringify: null,
  );

  Map<String, Object?> toJson() {
    return {
      inToStringName: inToString,
      stringifyName: stringify,
    };
  }
}

ToStringKeyInternal<T> createToStringKey<T>(ResolvedLibraryResult resolved, Map<String, DartObject?> map) {
  const String toStringKeyName = ToStringKeyInternal.srcAnnotationName;
  const String stringifyName = ToStringKeyInternal.stringifyName;

  ExecutableElement? stringify = map[stringifyName]?.toFunctionValue();

  AnnotationParameterLookupVisitor stringifyLookup = AnnotationParameterLookupVisitor(
    parameterName: stringifyName,
    element: stringify,
  );

  stringifyLookup.run(resolved.units);

  String? stringifyFunction = stringifyLookup.result;

  if (stringify != null && stringifyFunction == null) {
    couldNotResolveFunction(stringifyName, stringify.toString(), toStringKeyName);
    stringifyFunction = stringify.getFunctionName();
  }

  return ToStringKeyInternal(
    inToString: map[ToStringKeyInternal.inToStringName]!.toValue()! as bool,
    stringify: stringifyFunction,
  );
}
