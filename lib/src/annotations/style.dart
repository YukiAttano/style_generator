class Style {
  /// The name of the constructor that should be used for copyWith() and lerp()
  /// Example: `Style.fromJson(Map<String, Object?> json)` will be `fromJson`.
  // The displayName would be `Style.fromJson`
  ///
  /// * `null` enables auto guessing of the constructor
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  const Style({String? constructor}) : constructor = constructor == "" ? "new" : constructor;

  factory Style.fromJson(Map<String, Object?> json) {

    return Style(
      constructor: json["constructor"]?.toString(),
    //  list: List<int>.from(json["list"] as List<Object?>),
    //  test: (json["test"] as num).toDouble(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor" : constructor,
    };
  }
}


