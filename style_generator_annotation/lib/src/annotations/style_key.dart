import "package:meta/meta.dart";
import "package:meta/meta_meta.dart";

typedef LerpCallback<T> = T Function(T? a, T? b, double t);
typedef MergeCallback<T> = T Function(T a, T other);

/// override the generation behavior of a field
///
/// Annotations on constructor parameters take precedence over fields
@Target({
  TargetKind.field,
  TargetKind.parameter,
  TargetKind.optionalParameter,
  TargetKind.getter,
  TargetKind.overridableMember,
})
@optionalTypeArgs
class StyleKey<T> {
  /// if false, the field will not be included in the copyWith() method
  ///
  /// if the field is excluded, consider excluding it in [inMerge] too,
  /// otherwise the generated code might be invalid
  final bool inCopyWith;

  /// if false, the field will not be included in the merge() method
  final bool inMerge;

  /// if false, the field will not be included in the lerp() method
  final bool inLerp;

  /// override the lerp function for this field
  ///
  /// must either be a top level function or a static function
  final LerpCallback<T>? lerp;

  /// override the merge function for this field
  ///
  /// must either be a top level function or a static function
  final MergeCallback<T>? merge;

  const StyleKey({
    bool? inCopyWith,
    bool? inMerge,
    bool? inLerp,
    this.lerp,
    this.merge,
  })  : inCopyWith = inCopyWith ?? true,
        inMerge = inMerge ?? true,
        inLerp = inLerp ?? true;

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
      "inMerge": inMerge,
      "inLerp": inLerp,
      "lerp": lerp,
      "merge": merge,
    };
  }
}
