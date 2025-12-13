import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";

typedef ParameterLookup = String Function(FormalParameterElement element);

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  /// maps the constructor initializer parameter names to their corresponding field names
  ///
  /// That is the part behind the colon `:`
  /// ```dart
  ///   SomeChild(
  ///     super.id, {
  ///     required String super.firstname,
  ///     required String last,
  ///     String? private,
  ///     String another = "",
  ///     DateTime? birth,
  ///   })
  ///   // this parameters are mapped against their target field names
  ///   : private = private ?? "",
  ///     another = another,
  ///     super(lastname: last, birthday: birth ?? DateTime.now());
  /// ```
  ///
  /// Since one part of the initializers is for class-local field initialization and the other one for super-class parameters,
  /// the [lookup] method is required to look trough the structure of a super constructor to find the correct field.
  Map<String, String> mapParameterToField({
    required ParameterLookup lookup,
  }) {
    Map<String, String> map = {};

    for (var i in initializers) {
      switch (i) {
        // Those who are assigned to the same class
        case ConstructorFieldInitializer():
          String fieldName = i.fieldName.name;
          Expression expr = i.expression;

          // If Constructor is: `Some({String? private, String other}) : private = private ?? "", other = other;`
          // Than expr is: `private = private ?? ""`
          if (expr is BinaryExpression) expr = expr.leftOperand;

          // If Constructor is: `Some({String? private, String other}) : private = private ?? "", other = other;`
          // Than expr is: `other = other`
          if (expr is SimpleIdentifier) {
            map[expr.name] = fieldName;
          }
        // Those who are redirecting to the super class
        // Example: `super(lastname: last, birthday: birth ?? DateTime.now());`
        case SuperConstructorInvocation():
          _handleArguments(map, i.argumentList.arguments, lookup);
        // Those who are redirecting to another constructor
        // Example: `this._private(lastname: last, birthday: birth ?? DateTime.now());`
        case RedirectingConstructorInvocation():
          _handleArguments(map, i.argumentList.arguments, lookup);

        case AssertInitializer():
          break;
      }
    }

    return map;
  }

  void _handleArguments(Map<String, String> map, NodeList<Expression> arguments, ParameterLookup lookup) {
    for (var argument in arguments) {
      Expression? expr;

      switch (argument) {
        case SimpleIdentifier():
          expr = argument;
        case NamedExpression():
          expr = argument.expression;
      }

      if (expr is BinaryExpression) expr = expr.leftOperand;

      switch (expr) {
        case SimpleIdentifier():
          map[expr.name] = lookup(argument.correspondingParameter!);
        //argument.correspondingParameter!.displayName;
      }
    }
  }
}
