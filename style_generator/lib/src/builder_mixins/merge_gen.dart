import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/element/type.dart";

import "../../style_generator.dart";
import "../annotations/style_key_internal.dart";
import "../data/annotation_converter.dart";
import "../data/class_method.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

mixin MergeGen {
  static String get _nl => newLine;
  static const String methodName = "merge";

  String generateMerge(
    ResolvedLibraryResult resolvedLib,
    String className,
    List<Variable> params,
    AnnotationConverter<StyleKeyInternal> styleKeyAnnotation,
  ) {
    List<String> copyWithParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String name;
    bool inMerge;
    for (var p in params) {
      name = p.name!;

      styleKey = p.getAnnotationOf(styleKeyAnnotation);
      inMerge = _includeVariable(p, styleKey, className);
      prefix = inMerge ? "" : "//";

      copyWithParams.add(
        "$prefix $name: ${_getMergeMethod(resolvedLib, p, mergeMethod: styleKey?.merge, a: name, b: "other.$name")},",
      );
    }

    String function = """
    $className $methodName(ThemeExtension<$className>? other) {
      if (other is! $className) return this as $className;
    
      return copyWith(
        ${copyWithParams.join(_nl)}
      );
    }
    """;

    return function;
  }

  String _getMergeMethod(
    ResolvedLibraryResult resolvedLib,
    Variable variable, {
    String? mergeMethod,
    required String a,
    required String b,
  }) {
    ResolvedType resolvedType = variable.resolvedType;
    DartType d = resolvedType.type.extensionTypeErasure;
    String typePrefix = resolvedType.typePrefix;
    bool isNullable = d.isNullable;

    if (mergeMethod != null) {
      return "$mergeMethod($a, $b)";
    } else if (d is InterfaceType) {
      ClassMethod? mergeMethod = d.findMethod(resolvedLib.element, methodName);

      if (mergeMethod != null) {
        if (mergeMethod.isStatic) {
          return "$typePrefix${mergeMethod.methodHead}($a, $b)";
        } else {
          if (isNullable) {
            return "$a?.$methodName($b) ?? $b";
          } else {
            return "$a.$methodName($b)";
          }
        }
      }
    }

    return b;
  }

  bool _includeVariable(Variable v, StyleKeyInternal? styleKey, String clazz) {
    bool include = styleKey?.inMerge ?? true;

    return include;
  }
}
