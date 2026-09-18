import "package:meta/meta_meta.dart";

/// Classes annotated with @CopyWith() will generate a copyWith() method
@Target({TargetKind.classType})
class CopyWith {
  /// The name of the constructor that should be used for copyWith()
  /// Example: `CopyWith.fromJson(Map<String, Object?> json)` will be `fromJson`.
  // The displayName would be `CopyWith.fromJson`
  ///
  /// * `null` enables auto guessing of the constructor (the default)
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  /// will generate the method as an extension
  ///
  /// * `true` generates as extension method (default)
  /// * `null` will depend on the build.yml value
  /// * `false` generates as mixin (requires `with _$[ClassName]Cw` on the class)
  ///
  /// If `true`, [suffix] will be applied to the name of the extension class
  ///
  /// If 'false', type definitions of super classes have to be imported manually
  final bool? asExtension;

  /// The suffix is applied to the generated mixin
  ///
  /// Example:
  /// ```dart
  /// @CopyWith(suffix: "Copy")
  /// class Something with _$SomethingCopy {}
  ///
  /// // generates either a class
  /// mixin _$SomethingCopy {}
  ///
  /// // or an extension
  /// extension $SomethingCopy on Something {}
  /// ```
  final String? suffix;

  const CopyWith({
    this.constructor,
    this.asExtension,
    this.suffix,
  });

  factory CopyWith.fromJson(Map<String, Object?> json) {
    return CopyWith(
      constructor: json["constructor"]?.toString(),
      asExtension: json["asExtension"] as bool?,
      suffix: json["suffix"] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor": constructor,
      "asExtension": asExtension,
      "suffix": suffix,
    };
  }
}
