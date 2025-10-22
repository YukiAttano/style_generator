mixin OfGen {
  String generateOf(String className, String fallbackConstructor) {
    String function =
        """
        $className _\$${className}Of(BuildContext context, [$className? style]) {
          $className s = $className.$fallbackConstructor(context);
          s = s.merge(Theme.of(context).extension<$className>());
          s = s.merge(style);
    
          return s;
        }
        """;

    return function;
  }
}
