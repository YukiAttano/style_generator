/// @docImport "package:style_generator_annotation/copy_with_generator_annotation.dart";
library;

import "package:meta/meta.dart";

/// The internal representation of [CopyWithKey]
class CopyWithKeyInternal {
  static const String srcAnnotationName = "CopyWithKey";
  static const String inCopyWithName = "inCopyWith";
  static const String unmodifiableName = "unmodifiable";
  static const String fieldName = "field";

  final bool inCopyWith;
  final bool unmodifiable;
  final String? field;

  const CopyWithKeyInternal({
    required this.inCopyWith,
    required this.unmodifiable,
    required this.field,
  });

  /// These defaults must be the same as the one set by [CopyWithKey]
  @internal
  static const CopyWithKeyInternal defaults = CopyWithKeyInternal(
    inCopyWith: true,
    unmodifiable: false,
    field: null,
  );

  factory CopyWithKeyInternal.fromJson(Map<String, Object?> json) {
    return CopyWithKeyInternal(
      inCopyWith: json[inCopyWithName]! as bool,
      unmodifiable: json[unmodifiableName]! as bool,
      field: json[fieldName] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      inCopyWithName: inCopyWith,
      unmodifiableName: unmodifiable,
      fieldName: field,
    };
  }
}
