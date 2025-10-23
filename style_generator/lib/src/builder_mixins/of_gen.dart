import "../data/variable.dart";

mixin OfGen {

  /// [contextParameter] is expected to be null only if generation of this method is forced without having a valid [fallbackConstructor]
  String generateOf(String className, Variable? contextParameter, String fallbackConstructor) {
    String parameter = _getParameter(contextParameter);

    String function = """
        $className _\$${className}Of(BuildContext context, [$className? style]) {
          $className s = $className.$fallbackConstructor($parameter);
          s = s.merge(Theme.of(context).extension<$className>());
          s = s.merge(style);
    
          return s;
        }
        """;

    return function;
  }

  /// will generate either a positional or named context parameter
  ///
  /// if [contextParameter] is null, we fall back to a positional parameter.
  String _getParameter(Variable? contextParameter) {

    if (contextParameter == null) return "context";

    String name = contextParameter.displayName;

    String parameter;

    if (contextParameter.isNamed) {
      parameter = "$name: context";
    } else {
      parameter = "context";
    }

    return parameter;
  }
}
