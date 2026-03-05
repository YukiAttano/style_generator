import "package:meta/meta_meta.dart";

/// Classes annotated with @Equality() will generate a '==' and hash() method
@Target({TargetKind.classType})
class Equality {

  /// The suffix is applied to the generated mixin
  ///
  /// Example:
  /// ```dart
  /// @Equality(suffix: "S")
  /// class Some with _$SomeS {}
  ///
  /// // generates
  /// mixin SomeS {}
  /// ```
  final String? suffix;

  const Equality({
    this.suffix,
});

  factory Equality.fromJson(Map<String, Object?> json) {
    return Equality(
      suffix: json["suffix"] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "suffix": suffix,
    };
  }
}
