import "package:analyzer/dart/ast/ast.dart";

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
  Map<String, String> mapParameterToField() {
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
        // Those who are assigned to the super class
        // Example: `super(lastname: last, birthday: birth ?? DateTime.now());`
        case SuperConstructorInvocation():
          for (var argument in i.argumentList.arguments) {
            Expression? expr;

            switch (argument) {
              case NamedExpression():
                expr = argument.expression;
            }

            if (expr is BinaryExpression) expr = expr.leftOperand;

            switch (expr) {
              case SimpleIdentifier():
                map[expr.name] = argument.correspondingParameter!.displayName;
            }
          }

        case AssertInitializer():
          break;
        case RedirectingConstructorInvocation():
          break;
      }
    }

    return map;
  }
}
