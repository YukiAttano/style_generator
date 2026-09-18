import "package:style_generator_annotation/to_string_generator_annotation.dart";

import "../builder/config.dart";

class ToStringConfig extends ToString implements Config<ToStringConfig> {
  static const String srcAnnotationName = "ToString";

  @override
  String get suffix => super.suffix!;

  const ToStringConfig({
    required String suffix,
  }) : super(
         suffix: suffix,
       );

  factory ToStringConfig.fromConfig(Map<String, Object?> config) {
    return ToStringConfig(
      suffix: config["suffix"] as String? ?? "",
    );
  }

  @override
  ToStringConfig apply(ToString other) {
    return ToStringConfig(
      suffix: other.suffix ?? suffix,
    );
  }
}
