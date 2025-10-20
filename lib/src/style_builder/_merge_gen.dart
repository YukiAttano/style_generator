part of 'builder_state.dart';

mixin _MergeGen {

  static String get _nl => BuilderState._nl;


  String _generateMerge(LibraryElement lib, String className, List<Variable> fields) {
    List<String> copyWithParams = [];

    String name;
    for (var field in fields) {
      name = field.name!;

      copyWithParams.add("$name: ${_getMergeMethod(lib, field, a: name, b: "other.$name")},");
    }

    String function = """
    $className merge(ThemeExtension<$className>? other) {
      if (other is! $className) return this as $className;
    
      return copyWith(
        ${copyWithParams.join(_nl)}
      );
    }
    """;

    return function;
  }

  String _getMergeMethod(LibraryElement lib, Variable field, {required String a, required String b,}) {
    DartType d = field.type.extensionTypeErasure;
    String   suffix = field.type.isNullable ? "?" : "";

    var typeSystem = lib.typeSystem;
    var typeProvider = lib.typeProvider;
    //var themeExtensionType = (typeProvider.objectElement.library.exportNamespace.get2('ThemeExtension<Object?>') as ClassElement).thisType;

    if (d is InterfaceType) {
      MethodElement? lerpMethod = d.element.methods.firstWhereOrNull((method) => method.name == "merge");

      if (lerpMethod != null) {
        if (lerpMethod.isStatic) {
          return "${typeSystem.promoteToNonNull(d)}.merge($a, $b)";
        } else {
          return "$a$suffix.merge($b)";
        }
      }
    }


    return b;
  }
}

