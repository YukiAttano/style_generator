import 'package:style_generator/src/data/annotation_converter.dart';
import 'package:style_generator/src/data/variable.dart';
import 'package:style_generator/src/extensions/dart_type_extension.dart';
import 'package:style_generator/style_generator.dart';

import '../annotations/style_key_internal.dart';

mixin CopyWithGen {
  static String get _nl => newLine;

  String generateCopyWith(
    String className,
    String constructor,
    List<Variable> fields,
    AnnotationConverter<StyleKeyInternal> styleKeyAnnotation,
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
