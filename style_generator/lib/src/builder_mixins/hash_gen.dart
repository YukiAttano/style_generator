import "package:analyzer/dart/analysis/results.dart";

import "../../style_generator.dart";
import "../data/logger.dart";
import "../data/resolved_import.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

class HashGenResult {
  /// the generated function
  final String content;

  const HashGenResult({this.content = ""});
}

mixin HashGen {
  static String get _nl => newLine;
  static const String methodName = "hash";

  HashGenResult generateHash(
    List<Variable> fields,
    bool? Function(Variable v) inHashCallback,
  ) {
    List<String> f = [];

    String prefix;
    String name;
    bool inHash;
    String fieldName;
    bool hasFields = false;

    for (var v in fields) {
      name = v.name!;

      fieldName = v.fieldElement?.displayName ?? name;

      inHash = _includeVariable(v, inHashCallback);

      hasFields |= inHash;
      prefix = inHash ? "" : "//";

      f.add("$prefix$fieldName");
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
