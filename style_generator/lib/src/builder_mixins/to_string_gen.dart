import "../annotations/to_string_key_internal.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/variable.dart";

class ToStringGenResult {
  /// the generated function
  final String content;

  const ToStringGenResult({this.content = ""});
}

mixin ToStringGen {
  static const String methodName = "toString";

  ToStringGenResult generateToString(
    List<Variable> fields,
    String className,
    AnnotationConverter<ToStringKeyInternal> styleKeyAnnotation,
  ) {
    List<String> f = [];
    List<String> excluded = [];

    bool inToString;
    String fieldName;
    String line;
    ToStringKeyInternal? toStringKey;
    for (var v in fields) {
      fieldName = v.fieldElement?.displayName ?? v.displayName;

      toStringKey = v.getAnnotationOf(styleKeyAnnotation);
      inToString = _includeVariable(v, toStringKey, className);

      line = "$fieldName:${_getToStringMethod(fieldName, toStringMethod: toStringKey?.stringify)}";

      if (inToString) {
        f.add(line);
      } else {
        excluded.add(fieldName);
      }
    }

    String toStringParameter = f.isEmpty ? "" : f.join(", ");
    String excludedLine = excluded.isNotEmpty ? "// Excluded: ${excluded.join(", ")}" : "";

    String function =
        """
    @override
    String $methodName() {
      $excludedLine
      return "$className($toStringParameter)";
    }
    """;

    return ToStringGenResult(
      content: function,
    );
  }

  bool _includeVariable(Variable v, ToStringKeyInternal? styleKey, String clazz) {
    bool include = styleKey?.inToString ?? ToStringKeyInternal.defaults.inToString;

    return include;
  }

  String _getToStringMethod(
    String fieldName, {
    String? toStringMethod,
  }) {
    if (toStringMethod != null) {
      return "\${$toStringMethod($fieldName)}";
    } else {
      return "\$$fieldName";
    }
  }
}
