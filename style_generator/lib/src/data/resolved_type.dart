import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/syntactic_entity.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";

import "../extensions/dart_type_extension.dart";
import "../extensions/element/element_extension.dart";
import "resolved_import.dart";

class TypeInformation {
  final TypeParameterElement parameter;
  final ResolvedType argument;

  const TypeInformation(this.parameter, this.argument);
}

class ResolvedType {
  final LibraryElement library;
  final DartType type;

  // TypedElement get typedElement => TypedElement(
  //       type: type as InterfaceType,
  //       element: type.element! as ClassElement,
  //       getTypeForArgument: (argument) => typeArguments.firstWhere((element) => element.type == argument),
  //     );

  final TypeAnnotation? typeAnnotation;

  /// whether code gen tools require to add this import, if they list imports
  bool get requireImport => !type.isFromDartCore || typeImport.hasPrefix;

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

  final List<TypeInformation> typeInformation;

  /// if [type] has type arguments, these are the imports of them
  ///
  /// Example:
  /// `Map<SomeType, SomeOtherType<SomeNestedType>>`
  List<ResolvedImport> typeArgumentImports({bool requiredOnly = true}) {
    List<ResolvedImport> imports = [];

    for (var info in typeInformation) {
      if (requiredOnly) {
        if (info.argument.requireImport) {
          imports.add(info.argument.import);
        }
      } else {
        imports.add(info.argument.import);
      }
    }

    return imports;
  }

  ResolvedImport get prefixedFieldImport => ResolvedImport(
        prefix: prefixReference?.name.lexeme ?? "",
        uri: type.element?.library?.uri ?? Uri(),
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
  String getDisplayString() => //"$typePrefix${type.getDisplayString()}";
      "$typePrefix${type.element?.displayName}${typeAsString()}${type.isNullable ? "?" : ""}";

  String typeAsString() {
    if (typeInformation.isEmpty) return "";

    return "<${typeInformation.map((e) => e.argument.getDisplayString()).join(",")}>";
  }

  late final ResolvedImport import = () {
    if (prefixReference != null) return prefixedFieldImport;
    if (importDirective != null) return indirectFieldImport;
    return typeImport;
  } ();

  ResolvedType({
    required this.library,
    required this.type,
    required this.typeAnnotation,
    required this.prefixReference,
    required this.importDirective,
    required this.typeInformation,
  });

  factory ResolvedType.resolve({required ResolvedLibraryResult resolvedLib, required PropertyInducingElement element}) {
    TypeAnnotation? typeAnnotation = _getPrefixType(resolvedLib, element);

    ImportDirective? importDirective;

    // we can safely use _searchImportDirectiveIn without the library check.
    // we prevent lookups for FieldElements that are defined in the same library,
    // because multiple import directives could cause false positives. See [DartTypeExtension._importImportsType] for an explanation.
    // This wouldn't be 'wrong', but because we only need this as a fallback if no explicit prefix on the type is given, right now, we can also safe some computing resources here.
    if (resolvedLib.element.library != element.library) {
      importDirective = element.type.searchImportDirectiveIn(resolvedLib);
    }

    return ResolvedType(
      library: element.library,
      type: element.type,
      typeAnnotation: typeAnnotation,
      prefixReference: _getPrefixReference(typeAnnotation),
      importDirective: importDirective,
      typeInformation: element.type is InterfaceType
          ? (element.type as InterfaceType).resolveTypeInformation(resolvedLib)
          : const [],
    );
  }

  factory ResolvedType.resolveInterfaceType({required ResolvedLibraryResult resolvedLib, required InterfaceType type}) {
    TypeAnnotation? typeAnnotation = _getPrefixType(resolvedLib, type.element);

    InterfaceElement element = type.element;

    ImportDirective? importDirective;

    // we can safely use _searchImportDirectiveIn without the library check.
    // we prevent lookups for FieldElements that are defined in the same library,
    // because multiple import directives could cause false positives. See [DartTypeExtension._importImportsType] for an explanation.
    // This wouldn't be 'wrong', but because we only need this as a fallback if no explicit prefix on the type is given, right now, we can also safe some computing resources here.
    if (resolvedLib.element.library != element.library) {
      importDirective = type.searchImportDirectiveIn(resolvedLib);
    }

    return ResolvedType(
      library: element.library,
      type: type,
      typeAnnotation: typeAnnotation,
      prefixReference: _getPrefixReference(typeAnnotation),
      importDirective: importDirective,
      typeInformation: type.resolveTypeInformation(resolvedLib),
    );
  }

  factory ResolvedType.resolveTypeParameterType({
    required ResolvedLibraryResult resolvedLib,
    required TypeParameterType type,
  }) {
    TypeAnnotation? typeAnnotation = _getPrefixType(resolvedLib, type.element);

    TypeParameterElement element = type.element;

    return ResolvedType(
      library: element.library!,
      type: type,
      typeAnnotation: typeAnnotation,
      prefixReference: _getPrefixReference(typeAnnotation),
      importDirective: null,
      typeInformation: [],
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
  static TypeAnnotation? _getPrefixType(ResolvedLibraryResult resolvedLib, Element element) {
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
        library: library,
        type: type.extensionTypeErasure,
        typeAnnotation: typeAnnotation,
        prefixReference: prefixReference,
        importDirective: importDirective,
        typeInformation: typeInformation,
      );
}
