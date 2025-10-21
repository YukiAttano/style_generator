part of 'builder_state.dart';

mixin _CopyWithGen {
  static String get _nl => BuilderState._nl;

  String _generateCopyWith(
    String className,
    String constructor,
    List<Variable> fields,
    AnnotationBuilder<StyleKeyInternal> styleKeyAnnotation,
  ) {
    List<String> params = [];
    List<String> constructorParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String? name;
    String suffix;
    for (var field in fields) {
      name = field.name;
      suffix = field.type.isNullable ? "" : "?";

      styleKey = field.getAnnotationOf(styleKeyAnnotation);
      prefix = styleKey?.inCopyWith ?? true ? "" : "//";

      params.add("$prefix ${field.type}$suffix $name,");
      constructorParams.add("$prefix $name: $name ?? this.$name,");
    }

    String function =
        """
    $className copyWith({${params.join(_nl)}}) {
      return $className.$constructor(
        ${constructorParams.join(_nl)}
      );
    }
    """;

    return function;
  }
}
