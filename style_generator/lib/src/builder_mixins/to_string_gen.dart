import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/element/type.dart";

import "../annotations/to_string_key_internal.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

class ToStringGenResult {
  /// the generated function
  final String content;

  const ToStringGenResult({this.content = ""});
}

mixin ToStringGen {
  static const String methodName = "toString";

  ToStringGenResult generateToString(
    ResolvedLibraryResult resolvedLib,
    List<Variable> fields,
    String className,
    AnnotationConverter<ToStringKeyInternal> toStringKeyAnnotation,
  ) {
    List<String> f = [];
    List<String> excluded = [];

    bool inToString;
    String fieldName;
    String line;
    ToStringKeyInternal? toStringKey;
    for (var v in fields) {
      fieldName = _getFieldName(v);

      toStringKey = v.getAnnotationOf(toStringKeyAnnotation);
      inToString = _includeVariable(v, toStringKey, className);

      line = "$fieldName:${_getToStringMethod(resolvedLib, v, toStringMethod: toStringKey?.stringify)}";

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
      return '$className($toStringParameter)';
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

  String _getFieldName(Variable v) => v.fieldElement?.displayName ?? v.displayName;

  String _getToStringMethod(
    ResolvedLibraryResult resolvedLib,
    Variable variable, {
    String? toStringMethod,
  }) {
    ResolvedType resolvedType = variable.resolvedType;
    DartType d = resolvedType.type.extensionTypeErasure;
    bool isNullable = d.isNullable;

    String fieldName = _getFieldName(variable);

    if (toStringMethod != null) {
      return "\${$toStringMethod($fieldName)}";
    } else {
      String value = "\$$fieldName";

      if (d.isDartCoreString) {
        value = '"$value"' ;
      }

      if (isNullable) {
        return "\${$fieldName == null ? 'null' : '$value'}";
      }

      return value;
    }
  }
}
