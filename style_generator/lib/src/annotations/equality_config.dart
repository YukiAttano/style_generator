import "package:style_generator_annotation/copy_with_generator_annotation.dart";
import "package:style_generator_annotation/equality_generator_annotation.dart";

import "../builder/config.dart";

class EqualityConfig extends Equality implements Config<Equality> {
  static const String srcAnnotationName = "Equality";

  @override
  String get suffix => super.suffix!;

  const EqualityConfig({
    required String super.suffix,
  });

  factory EqualityConfig.fromConfig(Map<String, Object?> config) {
    return EqualityConfig(
      suffix: config["suffix"] as String? ?? "",
    );
  }

  @override
  EqualityConfig apply(Equality other) {
    return EqualityConfig(
      suffix: other.suffix ?? suffix,
    );
  }
}
