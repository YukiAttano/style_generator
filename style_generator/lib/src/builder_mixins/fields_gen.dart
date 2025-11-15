import "package:analyzer/dart/analysis/results.dart";

import "../../style_generator.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";

mixin FieldsGen {
  static String get _nl => newLine;

  String generateFieldGetter(List<Variable> fields) {
    List<String> list = [];

    String? name;
    ResolvedType resolvedType;
    for (var field in fields) {
      resolvedType = field.resolvedType;
      name = field.name;

      list.add("${resolvedType.displayName} get $name;");
    }

    String content = """
    ${list.join(_nl)}
    """;

    return content;
  }
}
