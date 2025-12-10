/// @docImport "package:style_generator_annotation/style_generator_annotation.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../data/ast_visitor/annotation_parameter_lookup_visitor.dart";
import "../data/logger.dart";
import "../extensions/dart_object_extension.dart";

/// The internal representation of [CopyWithKey]
class CopyWithKeyInternal<T> {
  static const String srcAnnotationName = "CopyWithKey";
  static const String inCopyWithName = "inCopyWith";

  final bool inCopyWith;

  const CopyWithKeyInternal({
    required this.inCopyWith,
  });

  factory CopyWithKeyInternal.fromJson(Map<String, Object?> json) {
    return CopyWithKeyInternal(
      inCopyWith: json[inCopyWithName] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      inCopyWithName: inCopyWith,
    };
  }
}
