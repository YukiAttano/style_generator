part of 'builder_state.dart';

mixin _MergeGen {

  static String get _nl => BuilderState._nl;


  String _generateMerge(LibraryElement lib, String className, List<Variable> fields, AnnotationBuilder<StyleKeyInternal> styleKeyAnnotation,) {
    List<String> copyWithParams = [];

    StyleKeyInternal? styleKey;
    String prefix = "";
    String name;
    for (var field in fields) {
      name = field.name!;

      styleKey = field.getAnnotationOf(styleKeyAnnotation);
      prefix = styleKey?.inMerge ?? true ? "" : "//";
      copyWithParams.add("$prefix $name: ${_getMergeMethod(lib, field, a: name, b: "other.$name")},");
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
    bool isNullable = d.isNullable;

    var typeSystem = lib.typeSystem;
    var typeProvider = lib.typeProvider;
    //var themeExtensionType = (typeProvider.objectElement.library.exportNamespace.get2('ThemeExtension<Object?>') as ClassElement).thisType;

    if (d is InterfaceType) {
      MethodElement? mergeMethod = d.element.methods.firstWhereOrNull((method) => method.name == "merge");

      if (mergeMethod != null) {
        if (mergeMethod.isStatic) {
          return "${typeSystem.promoteToNonNull(d)}.merge($a, $b)";
        } else {
          if (isNullable) {
            return "$a?.merge($b) ?? $b";
          } else {
            return "$a.merge($b)";
          }
        }
      }
    }


    return b;
  }
}

