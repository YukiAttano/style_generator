
typedef LerpCallback<T> = T Function(T? a, T? b, double t);

class StyleKey<T> {
  final bool? inCopyWith;
  final bool? inMerge;
  final bool? inLerp;
  final String? functionCall;
  final LerpCallback<T>? lerp;

  const StyleKey.internal({bool? inCopyWith, bool? inMerge, bool? inLerp, this.lerp, this.functionCall})
      : inCopyWith = inCopyWith ?? true,
        inMerge = inMerge ?? true,
        inLerp = inLerp ?? true;

  const StyleKey({bool? inCopyWith, bool? inMerge, bool? inLerp, LerpCallback<T>? lerp}) : this.internal(
    inCopyWith: inCopyWith,
    inMerge: inMerge,
    inLerp: inLerp,
    lerp: lerp,
  );

  Map<String, Object?> toJson() {
    return {"inCopyWith": inCopyWith, "inMerge": inMerge, "inLerp": inLerp, "lerp": lerp};
  }
}
