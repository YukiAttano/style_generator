/// @docImport "package:style_generator_annotation/copy_with_generator_annotation.dart";
library;

/// The internal representation of [CopyWithKey]
class CopyWithKeyInternal<T> {
  static const String srcAnnotationName = "CopyWithKey";
  static const String inCopyWithName = "inCopyWith";
  static const String fieldName = "field";

  final bool inCopyWith;
  final String? field;

  const CopyWithKeyInternal({
    required this.inCopyWith,
    required this.field,
  });

  factory CopyWithKeyInternal.fromJson(Map<String, Object?> json) {
    return CopyWithKeyInternal(
      inCopyWith: json[inCopyWithName] as bool? ?? true,
      field: json[fieldName] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      inCopyWithName: inCopyWith,
      fieldName: field,
    };
  }
}
