part of 'builder_state.dart';

mixin _LerpGen {
  static String get _nl => BuilderState._nl;

  String _generateLerp(
    LibraryElement lib,
    String className,
    String constructor,
    List<Variable> fields,
    AnnotationBuilder<StyleKeyInternal> styleKeyAnnotation,
  ) {
    List<String> constructorParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String? name;
    for (var field in fields) {
      name = field.name;
      styleKey = field.getAnnotationOf(styleKeyAnnotation);

      styleKey = field.getAnnotationOf(styleKeyAnnotation);
      prefix = styleKey?.inMerge ?? true ? "" : "//";
      constructorParams.add(
        "$prefix $name: ${_getLerpMethod(lib, field, lerpMethod: styleKey?.lerp, a: "$name", b: "other.$name")},",
      );
    }

    String function =
        """
    $className lerp(covariant ThemeExtension<$className>? other, double t) {
      if (other is! $className) return this as $className;
    
      return $className.$constructor(
        ${constructorParams.join(_nl)}
      );
    }
    """;

    return function;
  }

  String _getLerpMethod(
    LibraryElement lib,
    Variable field, {
    String? lerpMethod,
    required String a,
    required String b,
  }) {
    DartType d = field.type.extensionTypeErasure;
    bool isNullable = d.isNullable;

    var typeSystem = lib.typeSystem;
    var typeProvider = lib.typeProvider;
    //var themeExtensionType = (typeProvider.objectElement.library.exportNamespace.get2('ThemeExtension<Object?>') as ClassElement).thisType;

    if (lerpMethod != null) {
      // nullability is enforced by type parameters, therefor no check here is required
      return "$lerpMethod($a, $b, t)";
    } else if (d.isDartCoreDouble || d.isDartCoreNum) {
      if (isNullable) return "lerpDouble($a, $b, t)";

      // if DataType of [d] can't be null, this method will never return null so forcing non-null will not be a problem
      return "lerpDouble($a, $b, t)!";
    } else if (d.isDartCoreInt) {
      if (isNullable) return "lerpDouble($a, $b, t)?.round()";

      return "lerpDouble($a, $b, t)!.round()";
    } else if (d is InterfaceType) {
      if (d.element.library.isDartCore) {
        if (d.element.name == 'Duration') return _lerpDurationMethod(d.isNullable, a, b);
      }

      MethodElement? lerpMethod = d.element.methods.firstWhereOrNull((method) => method.name == "lerp");

      if (lerpMethod != null) {
        if (lerpMethod.isStatic) {
          if (isNullable) return "${typeSystem.promoteToNonNull(d)}.lerp($a, $b, t)";

          return "${typeSystem.promoteToNonNull(d)}.lerp($a, $b, t)!";
        } else {
          if (isNullable) return "$a?.lerp($b, t) ?? $b";

          return "$a.lerp($b, t)";
        }
      }
    }

    return b;
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
