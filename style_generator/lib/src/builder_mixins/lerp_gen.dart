import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/element/type.dart";

import "../annotations/style_key_internal.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/class_method.dart";
import "../data/logger.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";
import "../builder/style/style_builder.dart";

class LerpGenResult {
  /// the generated function
  final String content;

  /// additional code that [content] depends on
  final Iterable<String> trailing;

  const LerpGenResult({this.content = "", this.trailing = const []});
}

class LerpMethodGenResult {
  /// the generated function
  final String content;

  /// additional code that [content] depends on
  final Iterable<String> trailing;

  const LerpMethodGenResult({required this.content, this.trailing = const []});
}

mixin LerpGen {
  static String get _nl => newLine;
  static const String methodName = "lerp";

  LerpGenResult generateLerp(
    ResolvedLibraryResult resolvedLib,
    String className,
    String constructor,
    List<Variable> params,
    AnnotationConverter<StyleKeyInternal> styleKeyAnnotation,
  ) {
    Set<String> trailing = {};
    List<String> namedConstructorParams = [];
    List<String> positionalConstructorParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String? name;
    bool inLerp;
    LerpMethodGenResult method;
    for (var v in params) {
      name = v.name;

      styleKey = v.getAnnotationOf(styleKeyAnnotation);
      inLerp = _includeVariable(v, styleKey, className);

      prefix = inLerp ? "" : "//";

      method = _getLerpMethod(resolvedLib, v, lerpMethod: styleKey?.lerp, className: className, a: "$name", b: "other.$name");

      if (v.isNamed) {
        namedConstructorParams.add("$prefix $name: ${method.content},");
      } else {
        positionalConstructorParams.add("$prefix ${method.content},");
      }

      trailing.addAll(method.trailing);
    }

    String positional = positionalConstructorParams.isEmpty ? "" : positionalConstructorParams.join(_nl);
    String named = namedConstructorParams.isEmpty ? "" : namedConstructorParams.join(_nl);

    String function = """
    $className $methodName(covariant ThemeExtension<$className>? other, double t) {
      if (other is! $className) return this as $className;
    
      return $className.$constructor(
        $positional
        $named
      );
    }
    """;

    return LerpGenResult(content: function, trailing: trailing);
  }

  LerpMethodGenResult _getLerpMethod(
    ResolvedLibraryResult resolvedLib,
    Variable variable, {
    String? lerpMethod,
    required String className,
    required String a,
    required String b,
  }) {
    ResolvedType resolvedType = variable.resolvedType;
    DartType d = resolvedType.type.extensionTypeErasure;
    String typePrefix = resolvedType.typePrefix;

    bool isNullable = d.isNullable;

    String content = b;
    List<String> trailing = [];

    if (lerpMethod != null) {
      // nullability is enforced by type parameters, therefor no check is required here
      content = "$lerpMethod($a, $b, t)";
    } else if (d.isDartCoreDouble || d.isDartCoreNum) {
      if (isNullable) {
        content = "lerpDouble($a, $b, t)";
      } else {
        // if DataType of [d] can't be null, this method will never return null so forcing non-null will not be a problem
        content = "lerpDouble($a, $b, t)!";
      }
    } else if (d.isDartCoreInt) {
      if (isNullable) {
        content = "lerpDouble($a, $b, t)?.round()";
      } else {
        content = "lerpDouble($a, $b, t)!.round()";
      }
    } else if (d is InterfaceType) {
      if (d.element.library.isDartCore) {
        if (d.element.name == "Duration") {
          content = _lerpDurationMethod(d.isNullable, a, b);
          trailing.add(_durationLerp(typePrefix));
        }
      } else {
        ClassMethod? m = d.findMethod(resolvedLib.element, methodName);

        if (m != null) {
          String methodHead = m.methodHead;

          if (m.isStatic) {
            String suffix = isNullable ? "" : "!";

            content = "$typePrefix$methodHead($a, $b, t)$suffix";
          } else {
            if (isNullable) {
              content = "$a?.$methodHead($b, t) ?? $b";
            } else {
              content = "$a.$methodHead($b, t)";
            }
          }
        }
      }
    }

    if (content == b) didNotFindLerpForParameter(variable, clazz: className);

    return LerpMethodGenResult(content: content, trailing: trailing);
  }

  String _lerpDurationMethod(bool nullable, String a, String b) {
    String function;

    if (nullable) {
      function = "$a == null || $b == null ? $b : _lerpDuration($a!, $b!, t)";
    } else {
      function = "_lerpDuration($a, $b, t)";
    }

    return function;
  }

  bool _includeVariable(Variable v, StyleKeyInternal? styleKey, String clazz) {
    bool include = styleKey?.inLerp ?? true;
    if (!include && (v.isPositional || v.isRequired)) {
      cannotIgnorePositionalOrRequiredParameter(v, clazz: clazz, method: methodName);
      include = true;
    }

    return include;
  }
}

String _durationLerp(String prefix) {
  String duration = "${prefix}Duration";
  return """
$duration _lerpDuration($duration a, $duration b, double t) {
  return $duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}
""";
}
