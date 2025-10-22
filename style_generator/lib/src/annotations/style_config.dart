import "package:style_generator_annotation/style_generator_annotation.dart";

class StyleConfig extends Style {
  @override
  bool get genCopyWith => super.genCopyWith!;

  @override
  bool get genMerge => super.genMerge!;

  @override
  bool get genLerp => super.genLerp!;

  @override
  bool get genOf => super.genOf!;

  bool get genFields => genCopyWith || genMerge || genLerp;

  bool get isDisabled => !genCopyWith && !genMerge && !genLerp && !genOf;

  const StyleConfig({
    super.constructor,
    super.fallback,
    required bool genCopyWith,
    required bool genMerge,
    required bool genLerp,
    required bool genOf,
  }) : super(genCopyWith: genCopyWith, genMerge: genMerge, genLerp: genLerp, genOf: genOf);

  factory StyleConfig.fromConfig(Map<String, Object?> config) {
    return StyleConfig(
      constructor: config["constructor"]?.toString(),
      fallback: config["fallback"]?.toString(),
      genCopyWith: config["gen_copy_with"] as bool? ?? true,
      genMerge: config["gen_merge"] as bool? ?? true,
      genLerp: config["gen_lerp"] as bool? ?? true,
      genOf: config["gen_of"] as bool? ?? true,
    );
  }

  StyleConfig apply(Style other) {
    return StyleConfig(
      constructor: other.constructor ?? constructor,
      fallback: other.fallback ?? fallback,
      genCopyWith: other.genCopyWith ?? genCopyWith,
      genMerge: other.genMerge ?? genMerge,
      genLerp: other.genLerp ?? genLerp,
      genOf: other.genOf ?? genOf,
    );
  }
}
