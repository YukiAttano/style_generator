import "package:meta/meta_meta.dart";

typedef LerpCallback<T> = T Function(T? a, T? b, double t);

@Target({
  TargetKind.field,
  TargetKind.parameter,
  TargetKind.optionalParameter,
  TargetKind.getter,
  TargetKind.overridableMember,
})
class StyleKey<T> {
  /// if false, the field will not be included in the copyWith() method
  ///
  /// if the field is excluded, consider excluding it in [inMerge] too
  /// to let the generator generate valid code
  final bool inCopyWith;

  /// if false, the field will not be included in the merge() method
  final bool inMerge;

  /// if false, the field will not be included in the lerp() method
  final bool inLerp;
  final LerpCallback<T>? lerp;

  const StyleKey({bool? inCopyWith, bool? inMerge, bool? inLerp, this.lerp})
    : inCopyWith = inCopyWith ?? true,
      inMerge = inMerge ?? true,
      inLerp = inLerp ?? true;

  Map<String, Object?> toJson() {
    return {"inCopyWith": inCopyWith, "inMerge": inMerge, "inLerp": inLerp, "lerp": lerp};
  }
}
