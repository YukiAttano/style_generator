import "../../style_generator.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";

mixin FieldsGen {
  static String get _nl => newLine;

  String generateFieldGetter(Iterable<Variable> fields) {
    List<String> list = [];

    String? name;
    ResolvedType resolvedType;
    for (var field in fields) {
      resolvedType = field.resolvedType;
      name = field.fieldElement?.displayName ?? name;

      list.add("${resolvedType.getDisplayString()} get $name;");
    }

    String content = """
    ${list.join(_nl)}
    """;

    return content;
  }
}
