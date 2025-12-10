import "package:style_generator_annotation/copy_with_generator_annotation.dart";

class CopyWithConfig extends CopyWith {

  static const String srcAnnotationName = "CopyWith";

  @override
  String get suffix => super.suffix!;

  const CopyWithConfig({
    super.constructor,
    super.asExtension,
    required super.suffix,
  });

  factory CopyWithConfig.fromConfig(Map<String, Object?> config) {
    return CopyWithConfig(
      constructor: config["constructor"]?.toString(),
      asExtension: config["asExtension"] as bool?,
      suffix: config["suffix"] as String? ?? "",
    );
  }

  CopyWithConfig apply(CopyWith other) {
    return CopyWithConfig(
      constructor: other.constructor ?? constructor,
      asExtension: other.asExtension ?? asExtension,
      suffix: other.suffix ?? suffix,
    );
  }
}
