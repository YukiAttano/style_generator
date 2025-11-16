import "../../style_generator.dart";
import "../annotations/style_key_internal.dart";
import "../data/annotation_converter.dart";
import "../data/logger.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

mixin CopyWithGen {
  static String get _nl => newLine;
  static const String methodName = "copyWith";

  String generateCopyWith(
    String className,
    String constructor,
    List<Variable> parameters,
    AnnotationConverter<StyleKeyInternal> styleKeyAnnotation,
  ) {
    List<String> params = [];
    List<String> namedConstructorParams = [];
    List<String> positionalConstructorParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String name;
    bool inCopyWith;
    ResolvedType? resolvedType;
    String suffix;
    for (var v in parameters) {
      resolvedType = v.resolvedType;

      name = v.name!;
      suffix = v.type.isNullable ? "" : "?";

      styleKey = v.getAnnotationOf(styleKeyAnnotation);
      inCopyWith = _includeVariable(v, styleKey, className);

      prefix = inCopyWith ? "" : "//";

      params.add("$prefix ${resolvedType.displayName}$suffix $name,");
      if (v.isNamed) {
        namedConstructorParams.add("$prefix $name: $name ?? this.$name,");
      } else {
        positionalConstructorParams.add("$prefix $name ?? this.$name,");
      }
    }

    String parameter = params.isEmpty ? "" : "{$_nl${params.join(_nl)}$_nl}";
    String positional = positionalConstructorParams.isEmpty ? "" : positionalConstructorParams.join(_nl);
    String named = namedConstructorParams.isEmpty ? "" : namedConstructorParams.join(_nl);

    String function = """
    $className $methodName($parameter) {
      return $className.$constructor(
       $positional
       $named
      );
    }
    """;

    return function;
  }

  bool _includeVariable(Variable v, StyleKeyInternal? styleKey, String clazz) {
    bool include = styleKey?.inCopyWith ?? true;
    if (!include && (v.isPositional || v.isRequired)) {
      cannotIgnorePositionalOrRequiredParameter(v, clazz: clazz, method: methodName);
      include = true;
    }

    return include;
  }
}
