import "package:meta/meta_meta.dart";

/// Classes annotated with @ToString() will generate a toString() method
@Target({TargetKind.classType})
class ToString {
  /// will generate the method as an extension
  ///
  /// * `true` generates as extension method
  /// * `null` will depend on the build.yml value
  /// * `false` generates as mixin (requires `with _$[ClassName]Ts` on the class) (default)
  ///
  /// If `true`, [suffix] will be applied to the name of the extension class
  ///
  /// If 'false', type definitions of super classes have to be imported manually
  final bool? asExtension;

  /// The suffix is applied to the generated mixin
  ///
  /// Example:
  /// ```dart
  /// @ToString(suffix: "S")
  /// class Something with _$SomethingS {}
  ///
  /// // generates either a class
  /// mixin _$SomethingS {}
  ///
  /// // or an extension
  /// extension $SomethingS on Something {}
  /// ```
  final String? suffix;

  const ToString({
    this.asExtension,
    this.suffix,
  });

  factory ToString.fromJson(Map<String, Object?> json) {
    return ToString(
      asExtension: json["asExtension"] as bool?,
      suffix: json["suffix"] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "asExtension": asExtension,
      "suffix": suffix,
    };
  }
}
