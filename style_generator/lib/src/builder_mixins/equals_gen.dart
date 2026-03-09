import "../../style_generator.dart";
import "../data/variable.dart";

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

      if (v.resolvedType.requiresDeepEquality()) {
        buffer.write(
          "identical($fieldName, other.$fieldName) || const DeepCollectionEquality().equals($fieldName, other.$fieldName)$_nl",
        );
      } else {
        buffer.write("$fieldName == other.$fieldName$_nl");
      }
    }

    String function = """
    @override
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
