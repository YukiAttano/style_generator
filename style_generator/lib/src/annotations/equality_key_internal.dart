/// @docImport "package:style_generator_annotation/equality_generator_annotation.dart";
library;

import "package:meta/meta.dart";

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

  /// These defaults must be the same as the one set by [EqualityKey]
  @internal
  static const EqualityKeyInternal defaults = EqualityKeyInternal(inHash: true, inEquals: true,);

  factory EqualityKeyInternal.fromJson(Map<String, Object?> json) {
    return EqualityKeyInternal(
      inHash: json[inHashName]! as bool,
      inEquals: json[inEqualsName]! as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      inHashName: inHash,
      inEqualsName: inEquals,
    };
  }
}
