import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/syntactic_entity.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:collection/collection.dart";

import "../extensions/field_element_extension.dart";
import "resolved_import.dart";

class ResolvedType {
  final LibraryElement library;
  final DartType type;
  final TypeAnnotation? typeAnnotation;

  /// set, if the [type] is defined with a prefix `pre.Type variable`
  ///
  /// Example:
  /// ```dart
  /// import '../something.dart' as s;
  ///
  /// class SomeClass {
  ///   final s.Some some; // <-- This prefix is stored
  ///
  ///   SomeClass(this.some);
  /// }
  /// ```
  final ImportPrefixReference? prefixReference;

  /// set, if the import is explicitly defined
  /// _AND_ the element (which created this object) is not used in this library directly
  ///
  /// Example:
  /// ```dart
  /// import '../something.dart'; // <-- This is stored
  /// // import '../something.dart' as s; // <-- might carry a prefix
  ///
  /// class SomeClass extends SuperClass {
  ///   SomeClass(super.some); // <-- not used directly in this library
  /// }
  /// ```
  final ImportDirective? importDirective;

  ResolvedImport get prefixedFieldImport => ResolvedImport(
        prefix: prefixReference?.name.lexeme ?? "",
        uri: type.element!.library!.uri,
      );

  ResolvedImport get indirectFieldImport => ResolvedImport(
        prefix: importDirective?.prefix?.name ?? "",
        uri: (importDirective?.uri != null
                ? Uri.tryParse(importDirective!.uri.stringValue ?? importDirective!.uri.toString())
                : null) ??
            Uri(),
      );

  /// the source library of [type]
  ResolvedImport get typeImport => ResolvedImport(
        uri: type.element?.library?.uri ?? Uri(),
      );

  /// the string representation of [prefixReference]
  ///
  /// contains a trailing dot.
  ///
  /// Example: `fake.TextStyle` -> `fake.`
  String get typePrefix {
    var i = import;

    return i.prefix.isEmpty ? "" : "${i.prefix}.";
  }

  /// [typePrefix] and the display name of [type] combined
  ///
  /// Example: `fake.TextStyle`
  String get displayName => "$typePrefix${type.getDisplayString()}";

  ResolvedImport get import {
    if (prefixReference != null) return prefixedFieldImport;
    if (importDirective != null) return indirectFieldImport;
    return typeImport;
  }

  const ResolvedType({
    required this.library,
    required this.type,
    required this.typeAnnotation,
    required this.prefixReference,
    required this.importDirective,
  });

  factory ResolvedType.resolve({required ResolvedLibraryResult resolvedLib, required FieldElement element}) {
    TypeAnnotation? typeAnnotation = _getPrefixType(resolvedLib, element);

    ImportDirective? importDirective;

    // we can safely use _searchImportDirectiveIn without the library check.
    // we prevent lookups for FieldElements that are defined in the same library,
    // because multiple import directives could cause false positives. See [_importImportsType] for an explanation.
    // This wouldn't be 'wrong', but because we only need this as a fallback if no explicit prefix on the type is given, right now, we can also safe some computing resources here.
    if (resolvedLib.element.library != element.library) {
      importDirective  = _searchImportDirectiveIn(resolvedLib, element);
    }

    return ResolvedType(
      library: element.library,
      type: element.type,
      typeAnnotation: typeAnnotation,
      prefixReference: _getPrefixReference(typeAnnotation),
      importDirective: importDirective,
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

  /// if [element]s [DartType] is not defined in the current [resolvedLib] (e.g. the class definition is not in this file),
  /// we will lookup the current imports in [resolvedLib] to find one that matches the [DartType] of element.
  ///
  /// This is necessary, to allow prefixing imports of types that are defined in super classes.
  ///
  /// The returned directive may be wrong, if the defined import has a 'show' token which limits
  static ImportDirective? _searchImportDirectiveIn(ResolvedLibraryResult resolvedLib, FieldElement element) {
    ImportDirective? directive;

    LibraryElement? lookupLibrary = element.type.element?.library;

    if (resolvedLib.element != element.library) {
      lookupLibrary = element.type.element?.library;
    }

    ResolvedUnitResult unit = resolvedLib.units.first;
    List<ImportDirective> imports =
        unit.unit.sortedDirectivesAndDeclarations.whereType<ImportDirective>().toList(growable: false);

    for (var i in imports) {
      if (lookupLibrary == i.libraryImport?.importedLibrary) {
        if (i.combinators.isEmpty) {
          directive = i;
          break;
        } else if (_importImportsType(i, element.type) ?? true) {
          directive = i;
          break;
        }
      }
    }

    return directive;
  }

  /// checks if [i] imports [type]
  ///
  /// - true - if the [type] is explicitly shown
  /// - true - if the import has 'hide' combinators but [type] is not contained
  /// - false - if the [type] is explicitly hidden
  /// - false - if the import has 'show' combinators but [type] is not contained
  /// and `null` otherwise.
  ///
  /// this method may return false positives and false negatives
  /// if multiple imports consider to show the same [type] either explicitly or implicitly
  /// Example:
  /// ```dart
  /// import: 'some.dart' show Some;      // explicit import of Some
  /// import: 'some.dart' as show Some;  // explicit import of Some
  /// import: 'some.dart;                 // implicit import of Some
  /// ```
  static bool? _importImportsType(ImportDirective i, DartType type) {
    bool? imports;

    for (var c in i.combinators) {
      switch (c) {
        case ShowCombinator():
          imports = false;
          for (var name in c.shownNames) {
            if (name.element == type.element) {
              imports = true;
              break;
            }
          }
        case HideCombinator():
          imports = true;
          for (var name in c.hiddenNames) {
            if (name.element == type.element) {
              imports = false;
              break;
            }
          }
      }
    }

    return imports;
  }

  ResolvedType get extensionTypeErasure => ResolvedType(
        library: library,
        type: type.extensionTypeErasure,
        typeAnnotation: typeAnnotation,
        prefixReference: prefixReference,
        importDirective: importDirective,
      );
}
