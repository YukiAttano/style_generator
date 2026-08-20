import "package:analyzer/dart/analysis/results.dart";

import "../../style_generator.dart";
import "../data/logger.dart";
import "../data/resolved_import.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

class CopyWithGenResult {
  /// the generated function
  final String content;

  /// Additional code that [content] depends on
  final Iterable<ResolvedImport> imports;

  const CopyWithGenResult({this.content = "", this.imports = const []});
}

mixin CopyWithGen {
  static String get _nl => newLine;
  static const String methodName = "copyWith";

  CopyWithGenResult generateCopyWith(
    String className,
    String classTypes,
    String constructor,
    ResolvedLibraryResult resolvedLib,
    List<Variable> parameters,
    bool Function(Variable v) inCopyWithCallback,
    bool Function(Variable v) unmodifiableCallback,
    String? Function(Variable v) fieldCallback,
  ) {
    List<String> params = [];
    List<String> namedConstructorParams = [];
    List<String> positionalConstructorParams = [];

    List<ResolvedImport> imports = [];

    String prefixParam = "";
    String callingLine = "";
    String name;
    bool inCopyWith;
    bool unmodifiable;
    ResolvedType? resolvedType;
    String typeSuffix;
    String fieldName;

    for (var v in parameters) {
      if (v.isPrivate) cannotUsePrivateParameterInCopyWith(v, clazz: className);

      resolvedType = v.resolvedType;

      name = v.name!;

      typeSuffix = resolvedType.type.isNullable ? "" : "?";

      fieldName = v.preferField(fieldCallback(v), className)?.displayName ?? name;

      inCopyWith = _includeVariable(v, inCopyWithCallback, className);
      unmodifiable = unmodifiableCallback(v);

      prefixParam = inCopyWith && !unmodifiable ? "" : "//";

      if (resolvedType.requireImport) imports.add(resolvedType.import);
      imports.addAll(resolvedType.typeArgumentImports());

      params.add("$prefixParam ${resolvedType.getDisplayString()}$typeSuffix $name,");
      callingLine = _callingLine(isNamed: v.isNamed, inCopyWith: inCopyWith, unmodifiable: unmodifiable, name: name, fieldName: fieldName);

      if (v.isNamed) {
        namedConstructorParams.add(callingLine);
      } else {
        positionalConstructorParams.add(callingLine);
      }
    }

    String parameter = params.isEmpty ? "" : "{$_nl${params.join(_nl)}$_nl}";
    String positional = positionalConstructorParams.isEmpty ? "" : positionalConstructorParams.join(_nl);
    String named = namedConstructorParams.isEmpty ? "" : namedConstructorParams.join(_nl);

    String function = """
    $className$classTypes $methodName($parameter) {
      return $className.$constructor(
       $positional
       $named
      );
    }
    """;

    return CopyWithGenResult(
      imports: imports,
      content: function,
    );
  }

  String _callingLine({required bool isNamed, required bool inCopyWith, required bool unmodifiable, required String name, required  String fieldName}) {
    String prefix = inCopyWith ? "" : "//";

    String n = !unmodifiable ? "$name ??" : "/* $name ?? */";

    if (isNamed) {
      return "$prefix $name: $n this.$fieldName,";
    } else {
      return "$prefix $n this.$fieldName,";
    }
  }

  bool _includeVariable(Variable v, bool Function(Variable v) inCopyWithCallback, String clazz) {
    bool include = inCopyWithCallback(v);
    if (!include && (v.isPositional || v.isRequired)) {
      cannotIgnorePositionalOrRequiredParameter(v, clazz: clazz, method: methodName);
      include = true;
    }

    return include;
  }
}
