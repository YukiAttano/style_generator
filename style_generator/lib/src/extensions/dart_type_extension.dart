import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/nullability_suffix.dart";
import "package:analyzer/dart/element/type.dart";

import "../data/class_method.dart";
import "../data/resolved_import.dart";
import "../data/resolved_type.dart";

extension DartTypeExtension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;

  bool get isDartCore =>
      isBottom ||
      isDartAsyncFuture ||
      isDartAsyncFutureOr ||
      isDartAsyncStream ||
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreEnum ||
      isDartCoreFunction ||
      isDartCoreInt ||
      isDartCoreIterable ||
      isDartCoreList ||
      isDartCoreMap ||
      isDartCoreNull ||
      isDartCoreNum ||
      isDartCoreObject ||
      isDartCoreRecord ||
      isDartCoreSet ||
      isDartCoreString ||
      isDartCoreSymbol ||
      isDartCoreType;


  /// if `this` is not defined in the current [resolvedLib] (e.g. the class definition is not in this file),
  /// we will lookup the current imports in [resolvedLib] to find one that matches `this`.
  ///
  /// This is necessary, to allow prefixing imports of types that are defined in super classes.
  ///
  /// The returned directive might be wrong, if the defined import has a 'show' token
  ImportDirective? searchImportDirectiveIn(ResolvedLibraryResult resolvedLib) {
    ImportDirective? directive;

    LibraryElement? lookupLibrary = element?.library;

    if (lookupLibrary == resolvedLib.element) return null;

    ResolvedUnitResult unit = resolvedLib.units.first;
    List<ImportDirective> imports =
    unit.unit.sortedDirectivesAndDeclarations.whereType<ImportDirective>().toList(growable: false);

    loop: for (var i in imports) {
      if (lookupLibrary == i.libraryImport?.importedLibrary) {
        if (i.combinators.isEmpty) {
          directive = i;
          break;
        } else  {

          switch (_isImportImportingType(i, this)) {
            case null:
            case true:
              directive = i;
              break loop;
            case false:
          }
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
  /// import: 'some.dart' as show Some;   // explicit import of Some
  /// import: 'some.dart;                 // implicit import of Some
  /// ```
  static bool? _isImportImportingType(ImportDirective i, DartType type) {
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
}

extension InterfaceTypeExtension on InterfaceType {
  ClassMethod? findMethod(LibraryElement lib, String name) {
    MethodElement? m = element.lookUpMethod(library: lib, name: name);

    if (m == null) return null;

    return ClassMethod(type: this, element: m);
  }

  /// returns all imports for every type argument
  List<ImportDirective> getImports(ResolvedLibraryResult resolvedLib, [Set<ImportDirective>? imports]) {
    imports ??= {};

    ImportDirective? directive;
    for (var a in typeArguments) {
      directive = a.searchImportDirectiveIn(resolvedLib);
      if (directive != null) imports.add(directive);
    }

    return imports.toList();
  }

  /// recursively returns all imports for every type argument
  List<ResolvedImport> resolveImports(ResolvedLibraryResult resolvedLib, [Set<ResolvedImport>? imports]) {
    imports ??= {};

    ResolvedType resolvedType;
    for (var a in typeArguments) {
      if (a is InterfaceType) {
        resolvedType = ResolvedType.resolveInterfaceType(
          resolvedLib: resolvedLib,
          type: a,
        );
        imports.add(resolvedType.import);
      }
    }

    return imports.toList();
  }

  List<ResolvedType> resolveTypeArguments(ResolvedLibraryResult resolvedLib, [List<ResolvedType>? imports]) {
    imports ??= [];

    ResolvedType resolvedType;
    for (var a in typeArguments) {
      if (a is InterfaceType) {
        resolvedType = ResolvedType.resolveInterfaceType(
          resolvedLib: resolvedLib,
          type: a,
        );
        imports.add(resolvedType);
      }
    }

    return imports.toList();
  }
}
