/// @docImport "package:style_generator_annotation/style_generator_annotation.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../data/logger.dart";
import "../extensions/dart_object_extension.dart";

/// The internal representation of [StyleKey]
///
/// [StyleKey] forces the [lerp] method to be be correctly typed,
/// while this internal representation just holds the function name.
class StyleKeyInternal<T> {
  static const String srcAnnotationName = "StyleKey";
  static const String inCopyWithName = "inCopyWith";
  static const String inMergeName = "inMerge";
  static const String inLerpName = "inLerp";
  static const String lerpName = "lerp";
  static const String mergeName = "merge";

  final bool inCopyWith;
  final bool inMerge;
  final bool inLerp;
  final String? lerp;
  final String? merge;

  const StyleKeyInternal({
    required this.inCopyWith,
    required this.inMerge,
    required this.inLerp,
    required this.lerp,
    required this.merge,
  });

  Map<String, Object?> toJson() {
    return {
      inCopyWithName: inCopyWith,
      inMergeName: inMerge,
      inLerpName: inLerp,
      lerpName: lerp,
      mergeName: merge,
    };
  }
}

StyleKeyInternal<T> createStyleKey<T>(
  ResolvedLibraryResult resolved,
  CompilationUnit unit,
  Map<String, DartObject?> map,
) {
  const String styleKeyName = StyleKeyInternal.srcAnnotationName;
  const String lerpName = StyleKeyInternal.lerpName;
  const String mergeName = StyleKeyInternal.mergeName;

  ExecutableElement? lerp = map[lerpName]?.toFunctionValue();
  ExecutableElement? merge = map[mergeName]?.toFunctionValue();

  AnnotationParameterLookupVisitor lerpLookup =
      AnnotationParameterLookupVisitor(parameterName: lerpName, element: lerp);

  AnnotationParameterLookupVisitor mergeLookup =
      AnnotationParameterLookupVisitor(parameterName: mergeName, element: merge);

  lerpLookup.run(resolved.units);
  mergeLookup.run(resolved.units);

  String? lerpFunction = lerpLookup.result;
  String? mergeFunction = mergeLookup.result;

  if (lerp != null && lerpFunction == null) {
    couldNotResolveFunction(lerpName, lerp.toString(), styleKeyName);
    lerpFunction = _getFunctionName(lerp);
  }
  if (merge != null && mergeFunction == null) {
    couldNotResolveFunction(mergeName, merge.toString(), styleKeyName);
    mergeFunction = _getFunctionName(merge);
  }

  return StyleKeyInternal(
    inLerp: map[StyleKeyInternal.inLerpName]!.toValue()! as bool,
    inMerge: map[StyleKeyInternal.inMergeName]!.toValue()! as bool,
    inCopyWith: map[StyleKeyInternal.inCopyWithName]!.toValue()! as bool,
    lerp: lerpFunction,
    merge: mergeFunction,
  );
}

String? _getFunctionName(ExecutableElement? function) {
  String? callbackName;
  if (function != null) {
    if (function.isStatic) {
      switch (function.kind) {
        case ElementKind.METHOD:
          callbackName = "${function.enclosingElement?.displayName ?? ""}.${function.displayName}";
        case ElementKind.FUNCTION:
          callbackName = function.displayName;
      }
    } else {
      switch (function.kind) {
        case ElementKind.CONSTRUCTOR:
          callbackName = function.displayName;
      }
    }
  }

  return callbackName;
}

class AnnotationParameterLookupVisitor extends RecursiveAstVisitor<void> {
  final String parameterName;
  final ExecutableElement? element;
  String? result;

  AnnotationParameterLookupVisitor({required this.parameterName, required this.element});

  void run(List<ResolvedUnitResult> resolvedUnits) {
    if (element == null || resolvedUnits.isEmpty) return;

    for (var declaration in resolvedUnits) {
      declaration.unit.accept(this);

      if (result != null) break;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (result != null) return;

    for (var meta in node.metadata) {
      var list = meta.arguments?.arguments ?? [];

      for (var a in list) {
        if (a is NamedExpression && a.name.label.name == parameterName) {
          Expression expr = a.expression;

          Element? referred = _getElementFromExpression(expr);

          if (referred is ExecutableElement && element != null && referred == element) {
            result = expr.toSource();
          }
        }
      }
    }

    return super.visitFieldDeclaration(node);
  }
}

Element? _getElementFromExpression(Expression expression) {
  Element? element;

  switch (expression) {
    case PrefixedIdentifier():
      element = expression.element;
    case Identifier():
      element = expression.element;
    case PropertyAccess():
      element = expression.propertyName.element;
    case FunctionReference():
      element = _getElementFromExpression(expression.function);
    case MethodReferenceExpression():
      element = expression.element;
    case ConstructorReference():
      element = expression.constructorName.element;
  }

  return element;
}
