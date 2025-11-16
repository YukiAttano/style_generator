import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";

import "../logger.dart";

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
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (result != null) return;

    _evaluateNote(node);

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (result != null) return;

    _evaluateNote(node);

    return super.visitFieldDeclaration(node);
  }

  void _evaluateNote(AnnotatedNode node) {
    for (var meta in node.metadata) {
      var list = meta.arguments?.arguments ?? [];

      for (var a in list) {
        if (a is NamedExpression && a.name.label.name == parameterName) {
          Expression expr = a.expression;

          Element? referred = _getElementFromExpression(expr);

          if (referred == null) {
            unrecognizedExpression(expr, node);
          } else if (referred is ExecutableElement && element != null && referred == element) {
            result = expr.toSource();
          }
        }
      }
    }
  }
}

Element? _getElementFromExpression(Expression expression) {
  Element? element;

  switch (expression) {
    case PrefixedIdentifier():
      element = expression.element;
    case SimpleIdentifier():
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
