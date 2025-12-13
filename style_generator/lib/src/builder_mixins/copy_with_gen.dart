import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/element/type.dart";

import "../../style_generator.dart";
import "../data/logger.dart";
import "../data/resolved_import.dart";
import "../data/resolved_type.dart";
import "../data/variable.dart";
import "../extensions/dart_type_extension.dart";

class CopyWithGenResult {
  /// the generated function
  final String content;

  /// additional code that [content] depends on
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
    bool? Function(Variable v) inCopyWithCallback,
  ) {
    List<String> params = [];
    List<String> namedConstructorParams = [];
    List<String> positionalConstructorParams = [];

    List<ResolvedImport> imports = [];

    String prefix = "";
    String name;
    bool inCopyWith;
    ResolvedType? resolvedType;
    String typeSuffix;
    String fieldName;

    ResolvedImport import;
    for (var v in parameters) {

      resolvedType = v.resolvedType;

      name = v.name!;
      typeSuffix = resolvedType.type.isNullable ? "" : "?";

      fieldName = v.fieldElement?.displayName ?? name;

      inCopyWith = _includeVariable(v, inCopyWithCallback, className);

      prefix = inCopyWith ? "" : "//";

      import = resolvedType.import;

      if (import.hasPrefix || !resolvedType.type.isDartCore) {
        imports.add(import);
      }
      imports.addAll(resolvedType.typeArgumentImports);

      params.add("$prefix ${resolvedType.getDisplayString()}$typeSuffix $name,");
      if (v.isNamed) {
        namedConstructorParams.add("$prefix $name: $name ?? this.$fieldName,");
      } else {
        positionalConstructorParams.add("$prefix $name ?? this.$fieldName,");
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

  bool _includeVariable(Variable v,  bool? Function(Variable v) inCopyWithCallback, String clazz) {
    bool include = inCopyWithCallback(v) ?? true;
    if (!include && (v.isPositional || v.isRequired)) {
      cannotIgnorePositionalOrRequiredParameter(v, clazz: clazz, method: methodName);
      include = true;
    }

    return include;
  }
}
