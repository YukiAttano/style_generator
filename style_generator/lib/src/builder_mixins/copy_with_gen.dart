import "../../style_generator.dart";
import "../annotations/style_key_internal.dart";
import "../data/annotation_converter.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

mixin CopyWithGen {
  static String get _nl => newLine;

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
    String suffix;
    for (var v in parameters) {
      name = v.name!;
      suffix = v.type.isNullable ? "" : "?";

      styleKey = v.getAnnotationOf(styleKeyAnnotation);
      prefix = styleKey?.inCopyWith ?? true ? "" : "//";

      params.add("$prefix ${v.type}$suffix $name,");
      if (v.isNamed) {
        namedConstructorParams.add("$prefix $name: $name ?? this.$name,");
      } else {
        positionalConstructorParams.add("$prefix $name ?? this.$name,");
      }

    }

    String parameter = params.isEmpty ? "" : "{${params.join(_nl)}}";
    String positional = positionalConstructorParams.isEmpty ? "" : positionalConstructorParams.join(_nl);
    String named = namedConstructorParams.isEmpty ? "" : namedConstructorParams.join(_nl);

    String function =
        """
    $className copyWith($parameter) {
      return $className.$constructor(
       $positional
       $named
      );
    }
    """;

    return function;
  }
}
