/// @docImport "package:style_generator_annotation/copy_with_generator_annotation.dart";
library;

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
