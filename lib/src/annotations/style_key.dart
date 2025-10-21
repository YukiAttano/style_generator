
typedef LerpCallback<T> = T Function(T? a, T? b, double t);

class StyleKey<T> {
  final bool inCopyWith;
  final bool inMerge;
  final bool inLerp;
  final LerpCallback<T>? lerp;

  const StyleKey({bool? inCopyWith, bool? inMerge, bool? inLerp, this.lerp}) :
        inCopyWith = inCopyWith ?? true,
        inMerge = inMerge ?? true,
        inLerp = inLerp ?? true;

  Map<String, Object?> toJson() {
    return {"inCopyWith": inCopyWith, "inMerge": inMerge, "inLerp": inLerp, "lerp": lerp};
  }
}
