import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:collection/collection.dart";

import "../../style_generator.dart";
import "../annotations/style_key_internal.dart";
import "../data/annotation_converter.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

mixin MergeGen {
  static String get _nl => newLine;

  String generateMerge(
    LibraryElement lib,
    String className,
    List<Variable> fields,
    AnnotationConverter<StyleKeyInternal> styleKeyAnnotation,
  ) {
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

    String function =
        """
    $className merge(ThemeExtension<$className>? other) {
      if (other is! $className) return this as $className;
    
      return copyWith(
        ${copyWithParams.join(_nl)}
      );
    }
    """;

    return function;
  }

  String _getMergeMethod(LibraryElement lib, Variable field, {required String a, required String b}) {
    DartType d = field.type.extensionTypeErasure;
    bool isNullable = d.isNullable;

    var typeSystem = lib.typeSystem;

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
