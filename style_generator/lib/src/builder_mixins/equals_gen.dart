import "package:analyzer/dart/analysis/results.dart";

import "../../style_generator.dart";
import "../data/logger.dart";
import "../data/resolved_import.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

class EqualsGenResult {
  /// the generated function
  final String content;

  const EqualsGenResult({this.content = ""});
}

mixin EqualsGen {
  static String get _nl => newLine;
  static const String methodName = "operator ==";

  EqualsGenResult generateEquals(
    String className,
    List<Variable> fields,
    bool? Function(Variable v) inEqualsCallback,
  ) {
    String name;
    bool inHash;
    String fieldName;
    bool hasFields = false;

    StringBuffer buffer = StringBuffer();
    bool isFirst = true;

    for (var v in fields) {
      name = v.name!;

      fieldName = v.fieldElement?.displayName ?? name;

      inHash = _includeVariable(v, inEqualsCallback);
      hasFields = hasFields || inHash;

      if (!inHash) buffer.write("// ");

      if (!isFirst) {
        buffer.write("&& ");
      } else {
        if (inHash) isFirst = false;
      }

      buffer.write("$fieldName == other.$fieldName$_nl");
    }


    String function = """
    bool $methodName(Object other) {
      if (other is! $className) return false;
      
      return identical(this, other) ${hasFields ? "|| $buffer" : ""};
    }
    """;

    return EqualsGenResult(
      content: function,
    );
  }

  bool _includeVariable(Variable v, bool? Function(Variable v) inHashCallback) {
    return inHashCallback(v) ?? true;
  }
}
