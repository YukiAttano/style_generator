mixin OfGen {
  String generateOf(String className, String fallbackConstructor) {
    String function =
        """
        $className _\$of(BuildContext context, [$className? style]) {
          $className s = $className.$fallbackConstructor(context);
          s = s.merge(Theme.of(context).extension<SomeStyle>());
          s = s.merge(style);
    
          return s;
        }
        """;

    return function;
  }
}
