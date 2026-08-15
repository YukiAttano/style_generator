import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";

typedef ParameterLookup = Iterable<String> Function(FormalParameterElement element);

typedef InitializerFieldMap = Map<String, List<String>>;

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
  InitializerFieldMap mapInitializersToField({
    required ParameterLookup lookup,
    // print for debugging purpose
    void Function(dynamic p)? p,
  }) {
    InitializerFieldMap map = {};

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
            map.addValueToList(expr.name, fieldName);
            //map[expr.name] = fieldName;
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

  void _handleArguments(InitializerFieldMap map, NodeList<Expression> arguments, ParameterLookup lookup) {
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
          map.addListToList(expr.name, lookup(argument.correspondingParameter!));
          //map[expr.name] = lookup(argument.correspondingParameter!);

          // //argument.correspondingParameter!.displayName;
      }
    }
  }
}

extension _MapListExtension<K, V> on Map<K, List<V>> {
  void addValueToList(K key, V value) {
    List<V> list = this[key] ?? [];
    list.add(value);
    this[key] = list;
  }

  void addListToList(K key, Iterable<V> values) {
    List<V> list = this[key] ?? [];
    list.addAll(values);
    this[key] = list;
  }
}