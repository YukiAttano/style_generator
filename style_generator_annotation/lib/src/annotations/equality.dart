import "package:meta/meta_meta.dart";

/// Classes annotated with @Equality() will generate a '==' and hash() method
@Target({TargetKind.classType})
class Equality {
  /// The name of the constructor that should be used to lookup fields
  ///
  /// Example: `Equality.fromJson(Map<String, Object?> json)` will be `fromJson`.
  // The displayName would be `Equality.fromJson`
  ///
  /// By definition, we would only require the fields of the class without knowing any constructor.
  /// The constructor however allows us to use @EqualityKey overrides on super class fields.
  /// Without the constructor, overrides of @EqualityKeys are only possible via overriding the member or
  /// using getter access.
  ///
  /// Example:
  /// ```dart
  /// class Parent {
  ///   final int id;
  ///   final String name;
  ///
  ///   const Parent(this.id, this.name);
  /// }
  ///
  /// class Child extends Parent {
  ///   @override
  ///   @EqualityKey()
  ///   final int id;
  ///
  ///   @override
  ///   @EqualityKey()
  ///   String get name => super.name;
  ///
  ///   const Child(this.id, String name) : super(id, name);
  /// }
  /// ```
  ///
  /// We have decided that it is more usable depending on the constructor and allowing overrides on his parameters
  /// instead of the shown alternative, as this is the implementation of all other code generators in this library
  /// and therefor the most intuitive way.
  ///
  /// * `null` enables auto guessing of the constructor (the default)
  /// * `""` (Empty string) will use the default constructor
  /// * `"_example"` will use the _example constructor
  final String? constructor;

  /// The suffix is applied to the generated mixin
  ///
  /// Example:
  /// ```dart
  /// @Equality(suffix: "S")
  /// class Some with _$SomeS {}
  ///
  /// // generates
  /// mixin SomeS {}
  /// ```
  final String? suffix;

  const Equality({
    this.constructor,
    this.suffix,
  });

  factory Equality.fromJson(Map<String, Object?> json) {
    return Equality(
      constructor: json["constructor"] as String?,
      suffix: json["suffix"] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "constructor": constructor,
      "suffix": suffix,
    };
  }
}
