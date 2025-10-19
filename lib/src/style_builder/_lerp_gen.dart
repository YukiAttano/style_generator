part of 'builder_state.dart';

mixin _LerpGen {
  static String get _nl => BuilderState._nl;

  String _generateLerp(LibraryElement lib, String className, List<Variable> fields) {
    List<String> constructorParams = [];

    String? name;
    for (var field in fields) {
      name = field.name;

      constructorParams.add("$name: ${_getLerpMethod(lib, field, a: "$name", b: "other.$name")},");
    }

    String function =
        """
    $className lerp(covariant ThemeExtension<$className>? other, double t) {
      if (other is! $className) return this as $className;
    
      return $className(
        ${constructorParams.join(_nl)}
      );
    }
    """;

    return function;
  }

  String _getLerpMethod(LibraryElement lib, Variable field, {required String a, required String b}) {
    DartType d = field.type.extensionTypeErasure;
    String suffix = field.type.isNullable ? "?" : "";

    var typeSystem = lib.typeSystem;
    var typeProvider = lib.typeProvider;
    //var themeExtensionType = (typeProvider.objectElement.library.exportNamespace.get2('ThemeExtension<Object?>') as ClassElement).thisType;

    if (d.isDartCoreDouble || d.isDartCoreNum) {
      if (d.isNullable) return "lerpDouble($a, $b, t)";

      // if DataType of [d] can't be null, this method will never return null
      return "lerpDouble($a, $b, t)!";
    } else if (d.isDartCoreInt) {
      if (d.isNullable) return "lerpDouble($a, $b, t)?.round()";

      return "lerpDouble($a, $b, t)!.round()";
    } else if (d is InterfaceType) {
      if (d.element.library.isDartCore) {
        if (d.element.name == 'Duration') return _lerpDurationMethod(d.isNullable, a, b);
      }

      MethodElement? lerpMethod = d.element.methods.firstWhereOrNull((method) => method.name == "lerp");

      if (lerpMethod != null) {
        if (lerpMethod.isStatic) {
          return "${typeSystem.promoteToNonNull(d)}.lerp($a, $b, t)";
        } else {
          return "$a$suffix.lerp($b, t)";
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
