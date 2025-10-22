import "package:meta/meta_meta.dart";

@Target({TargetKind.classType})
class Style {
  /// The name of the constructor that should be used for copyWith() and lerp()
  /// Example: `Style.fromJson(Map<String, Object?> json)` will be `fromJson`.
  // The displayName would be `Style.fromJson`
  ///
  /// * `null` enables auto guessing of the constructor
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  /// The name of the constructor that should be used for the .of() constructor to create a default Style
  ///
  /// * `null` will remove the fallback (and stop generating the .of() factory constructor)
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? fallback;

  /// if true (the default) will generate a copyWith method
  ///
  /// if this is false, consider disabling [genMerge] too
  final bool genCopyWith;

  /// if true (the default) will generate a merge method
  ///
  /// requires a copyWith method
  final bool genMerge;

  /// if true (the default) will generate a lerp method
  final bool genLerp;

  const Style({String? constructor, String? fallback = "", bool? genCopyWith, bool? genMerge, bool? genLerp})
    : constructor = constructor == "" ? "new" : constructor,
      fallback = fallback == "" ? "new" : fallback,
      genCopyWith = genCopyWith ?? true,
      genMerge = genMerge ?? true,
      genLerp = genLerp ?? true;

  factory Style.fromJson(Map<String, Object?> json) {
    return Style(
      constructor: json["constructor"]?.toString(),
      fallback: json["fallback"]?.toString(),
      genCopyWith: json["genCopyWith"]! as bool,
      genMerge: json["genMerge"]! as bool,
      genLerp: json["genLerp"]! as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor": constructor,
      "fallback": fallback,
      "genCopyWith": genCopyWith,
      "genMerge": genMerge,
      "genLerp": genLerp,
    };
  }
}
