
import "../../style_generator.dart";
import "../data/variable.dart";

class HashGenResult {
  /// the generated function
  final String content;

  const HashGenResult({this.content = ""});
}

mixin HashGen {
  static String get _nl => newLine;
  static const String methodName = "hashCode";

  HashGenResult generateHash(
    List<Variable> fields,
    bool? Function(Variable v) inHashCallback,
  ) {
    List<String> f = [];

    String prefix;
    bool inHash;
    String fieldName;
    bool hasFields = false;

    for (var v in fields) {
      fieldName = v.fieldElement?.displayName ?? v.displayName;

      inHash = _includeVariable(v, inHashCallback);

      hasFields |= inHash;
      prefix = inHash ? "" : "// ";

      if (v.resolvedType.requiresDeepEquality()) {
        f.add("${prefix}const DeepCollectionEquality().hash($fieldName)");
      } else {
        f.add("$prefix$fieldName");
      }
    }

    String hashParameter = f.isEmpty ? "" : f.join(",$_nl");
    String hashAll = "Object.hashAll([$_nl$hashParameter$_nl])";
    String hashEmpty = "identityHashCode(this)";

    String function = """
    int get $methodName => ${!hasFields ? hashEmpty : hashAll};
    """;

    return HashGenResult(
      content: function,
    );
  }

  bool _includeVariable(Variable v, bool? Function(Variable v) inHashCallback) {
    return inHashCallback(v) ?? true;
  }
}
