import "package:meta/meta.dart";
import "package:meta/meta_meta.dart";

typedef StringCallback<T> = String Function(T field);

/// override the generation behavior of a field
///
/// - Annotations on constructor parameters take precedence over fields
/// - Annotations on fields are inherited in subclasses, while those on parameters are not
@Target({
  TargetKind.field,
  TargetKind.parameter,
  TargetKind.optionalParameter,
  TargetKind.getter,
  TargetKind.overridableMember,
})
@optionalTypeArgs
class ToStringKey<T> {
  /// if false, the field will not be included in the toString() method
  ///
  /// defaults to true
  final bool inToString;

  /// overrides the toString function for this field
  ///
  /// must either be a top level function or a static function
  final StringCallback<T>? stringify;

  const ToStringKey({
    bool? inToString,
    this.stringify,
  })  : inToString = inToString ?? true;

  Map<String, Object?> toJson() {
    return {
      "inToString": inToString,
      "stringify": stringify,
    };
  }
}
