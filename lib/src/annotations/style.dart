class Style {
  /// The constructor that should be used for copyWith() and lerp()
  ///
  /// * `null` enables auto guessing of the constructor
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  const Style({this.constructor});

  factory Style.fromJson(Map<String, Object?> json) {
    return Style(
      constructor: json["constructor"]?.toString(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor" : constructor,
    };
  }
}

