class Style {
  final String constructor;

  const Style({this.constructor = ""});

  factory Style.fromJson(Map<String, Object?> json) {
    return Style(
      constructor: (json["constructor"]?.toString() ?? ""),
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor" : constructor,
    };
  }
}

