import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:collection/collection.dart";

import "../annotations/style_key_internal.dart";
import "../data/annotation_converter.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";
import "../style_builder/style_builder.dart";

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

  LerpGenResult generateLerp(
    LibraryElement lib,
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
    LerpMethodGenResult method;
    for (var v in params) {
      name = v.name;

      styleKey = v.getAnnotationOf(styleKeyAnnotation);
      prefix = styleKey?.inLerp ?? true ? "" : "//";

      method = _getLerpMethod(lib, v, lerpMethod: styleKey?.lerp, a: "$name", b: "other.$name");

      if (v.isNamed) {
        namedConstructorParams.add("$prefix $name: ${method.content},");
      } else {
        positionalConstructorParams.add("$prefix ${method.content},");
      }

      trailing.addAll(method.trailing);
    }

    String positional = positionalConstructorParams.isEmpty ? "" : positionalConstructorParams.join(_nl);
    String named = namedConstructorParams.isEmpty ? "" : namedConstructorParams.join(_nl);

    String function =
        """
    $className lerp(covariant ThemeExtension<$className>? other, double t) {
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
    LibraryElement lib,
    Variable field, {
    String? lerpMethod,
    required String a,
    required String b,
  }) {
    DartType d = field.type.extensionTypeErasure;
    bool isNullable = d.isNullable;

    var typeSystem = lib.typeSystem;

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
          trailing.add(_durationLerp);
        }
      } else {
        MethodElement? lerpMethod = d.element.methods.firstWhereOrNull((method) => method.name == "lerp");

        if (lerpMethod != null) {
          if (lerpMethod.isStatic) {
            if (isNullable) {
              content = "${typeSystem.promoteToNonNull(d)}.lerp($a, $b, t)";
            } else {
              content = "${typeSystem.promoteToNonNull(d)}.lerp($a, $b, t)!";
            }
          } else {
            if (isNullable) {
              content = "$a?.lerp($b, t) ?? $b";
            } else {
              content = "$a.lerp($b, t)";
            }
          }
        }
      }
    }

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
}

const String _durationLerp = """
Duration _lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}
""";
