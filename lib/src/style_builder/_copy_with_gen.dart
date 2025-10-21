part of 'builder_state.dart';

mixin _CopyWithGen {
  static String get _nl => BuilderState._nl;

  String _generateCopyWith(String className, String constructor, List<Variable> fields) {
    List<String> params = [];
    List<String> constructorParams = [];

    String? name;
    String suffix;
    for (var field in fields) {
      name = field.name;
      suffix = field.type.isNullable ? "" : "?";

      params.add("${field.type}$suffix $name,");
      constructorParams.add("$name: $name ?? this.$name,");
    }


    String function = """
    $className copyWith({${params.join(_nl)}}) {
      return $className.$constructor(
        ${constructorParams.join(_nl)}
      );
    }
    """;

    return function;
  }
}

