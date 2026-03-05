/// @docImport "package:style_generator_annotation/equality_generator_annotation.dart";
library;

/// The internal representation of [EqualityKey]
class EqualityKeyInternal<T> {
  static const String srcAnnotationName = "EqualityKey";
  static const String inHashName = "inHash";
  static const String inEqualsName = "inEquals";

  final bool inHash;
  final bool inEquals;

  const EqualityKeyInternal({
    required this.inHash,
    required this.inEquals,
  });

  factory EqualityKeyInternal.fromJson(Map<String, Object?> json) {
    return EqualityKeyInternal(
      inHash: json[inHashName] as bool? ?? true,
      inEquals: json[inEqualsName] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      inHashName: inHash,
      inEqualsName: inEquals,
    };
  }
}
