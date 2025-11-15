import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/syntactic_entity.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";

import "../extensions/field_element_extension.dart";

class ResolvedType {
  final DartType type;
  final TypeAnnotation? typeAnnotation;
  final ImportPrefixReference? prefixReference;

  /// the string representation of [prefixReference]
  ///
  /// contains a trailing dot.
  ///
  /// Example: `fake.TextStyle` -> `fake.`
  String get typePrefix => prefixReference?.toString() ?? "";

  /// [typePrefix] and the display name of [type] combined
  ///
  /// Example: `fake.TextStyle`
  String get displayName => "$typePrefix${type.getDisplayString()}";

  const ResolvedType({required this.type, required this.typeAnnotation, required this.prefixReference});

  factory ResolvedType.resolve({required ResolvedLibraryResult resolvedLib, required FieldElement element}) {
    TypeAnnotation? typeAnnotation = _getPrefixType(resolvedLib, element);

    return ResolvedType(
      type: element.type,
      typeAnnotation: typeAnnotation,
      prefixReference: _getPrefixReference(typeAnnotation),
    );
  }

  /// returns the resolved type of [element]
  ///
  /// only a resolved type carries an import prefix information
  ///
  /// Example:
  /// ```dart
  /// import 'fake' as fake;
  ///
  /// TextStyle? titleStyle;
  /// fake.Color color;
  /// ```
  /// The type annotations in the example are `TextStyle?` and `fake.Color`
  static TypeAnnotation? _getPrefixType(ResolvedLibraryResult resolvedLib, FieldElement element) {
    return element.getPrefixedType(resolvedLib);
  }

  static ImportPrefixReference? _getPrefixReference(TypeAnnotation? annotation) {
    Iterable<SyntacticEntity>? entities = annotation?.childEntities;

    if (entities != null) {
      for (var e in entities) {
        if (e is ImportPrefixReference) {
          return e;
        }
      }
    }

    return null;
  }

  ResolvedType get extensionTypeErasure => ResolvedType(
        type: type.extensionTypeErasure,
        typeAnnotation: typeAnnotation,
        prefixReference: prefixReference,
      );
}
