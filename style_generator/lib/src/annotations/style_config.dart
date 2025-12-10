import "package:style_generator_annotation/style_generator_annotation.dart";

import "../builder/config.dart";

class StyleConfig extends Style implements Config<StyleConfig> {

  static const String srcAnnotationName = "Style";

  @override
  bool get genCopyWith => super.genCopyWith!;

  @override
  bool get genMerge => super.genMerge!;

  @override
  bool get genLerp => super.genLerp!;

  @override
  String get suffix => super.suffix!;

  bool get genFields => genCopyWith || genMerge || genLerp;

  bool get isDisabled => !genCopyWith && !genMerge && !genLerp && !(genOf ?? false);

  const StyleConfig({
    super.constructor,
    super.fallback,
    required bool genCopyWith,
    required bool genMerge,
    required bool genLerp,
    super.genOf,
    required String suffix,
  }) : super(
          genCopyWith: genCopyWith,
          genMerge: genMerge,
          genLerp: genLerp,
          suffix: suffix,
        );

  factory StyleConfig.fromConfig(Map<String, Object?> config) {
    return StyleConfig(
      constructor: config["constructor"]?.toString(),
      fallback: config["fallback"]?.toString(),
      genCopyWith: config["gen_copy_with"] as bool? ?? true,
      genMerge: config["gen_merge"] as bool? ?? true,
      genLerp: config["gen_lerp"] as bool? ?? true,
      genOf: config["gen_of"] as bool?,
      suffix: config["suffix"] as String? ?? "",
    );
  }

  @override
  StyleConfig apply(Style other) {
    return StyleConfig(
      constructor: other.constructor ?? constructor,
      fallback: other.fallback ?? fallback,
      genCopyWith: other.genCopyWith ?? genCopyWith,
      genMerge: other.genMerge ?? genMerge,
      genLerp: other.genLerp ?? genLerp,
      genOf: other.genOf ?? genOf,
      suffix: other.suffix ?? suffix,
    );
  }
}
