import "package:meta/meta_meta.dart";

@Target({TargetKind.classType})
class Style {
  /// The name of the constructor that should be used for copyWith() and lerp()
  /// Example: `Style.fromJson(Map<String, Object?> json)` will be `fromJson`.
  // The displayName would be `Style.fromJson`
  ///
  /// * `null` enables auto guessing of the constructor (the default)
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  /// The name of the constructor that should be used for the .of() constructor to create a default Style
  ///
  /// * `null` will use the default constructor (the default) (will not use auto guessing)
  /// * `""` (Empty string) will use the default constructor (the default)
  /// * `"_example"` will use the _example constructor
  final String? fallback;

  /// if true (the default) will generate a copyWith method
  ///
  /// if this is false, consider disabling [genMerge] too
  final bool? genCopyWith;

  /// if true (the default) will generate a merge method
  ///
  /// requires a `copyWith()` method
  final bool? genMerge;

  /// if true (the default) will generate a lerp method
  final bool? genLerp;

  /// will generate the factory .of constructor
  ///
  /// requires a `merge()` method
  ///
  /// * `true` forces generation
  /// * `null` will only generate if the [fallback] constructor matches
  /// the fallback prototype and a factory .of() constructor is given
  /// * `false` generation is disabled
  ///
  /// if all gen parameter are false and [genOf] is null, it is also considered false
  final bool? genOf;

  /// The suffix is applied to the generated mixin
  ///
  /// Example:
  /// ```dart
  /// @Style(mixinSuffix: "S")
  /// class SomeStyle extends ThemeExtension<Style> with _$SomeStyleS {}
  ///
  /// // generates
  /// mixin SomeStyleS {}
  /// ```
  final String? suffix;

  const Style({
    this.constructor,
    this.fallback,
    this.genCopyWith,
    this.genMerge,
    this.genLerp,
    this.genOf,
    this.suffix,
  });

  factory Style.fromJson(Map<String, Object?> json) {
    return Style(
      constructor: json["constructor"]?.toString(),
      fallback: json["fallback"]?.toString(),
      genCopyWith: json["genCopyWith"] as bool?,
      genMerge: json["genMerge"] as bool?,
      genLerp: json["genLerp"] as bool?,
      genOf: json["genOf"] as bool?,
      suffix: json["suffix"] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor": constructor,
      "fallback": fallback,
      "genCopyWith": genCopyWith,
      "genMerge": genMerge,
      "genLerp": genLerp,
      "genOf": genOf,
      "suffix": suffix,
    };
  }
}
