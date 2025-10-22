
import "../../style_generator.dart";
import "../data/variable.dart";

mixin FieldsGen {
  static String get _nl => newLine;

  String generateFieldGetter(List<Variable> fields) {
    List<String> f = [];

    String? name;
    for (var field in fields) {
      name = field.name;

      f.add("${field.type} get $name;");
    }

    String content = """
    ${f.join(_nl)}
    """;

    return content;
  }
}