import "package:meta/meta_meta.dart";

/// override the generation behavior of a field
///
/// - Annotations on constructor parameters take precedence over fields
/// - Annotations on fields are inherited in subclasses, while those on parameters do not
/// ```
@Target({
  TargetKind.field,
  TargetKind.parameter,
  TargetKind.optionalParameter,
  TargetKind.getter,
  TargetKind.overridableMember,
})
class EqualityKey {
  /// if false, the field will not be included in the hash method
  final bool inHash;

  /// if false, the field will not be included in the == method
  final bool inEquals;

  /// Use [EqualityKey.exclude]
  ///
  /// It is generally discouraged to only disable one and not the other.
  ///
  /// But who am I to take this option from you.
  const EqualityKey({
    bool? inHash,
    bool? inEquals,
  })  : inHash = inHash ?? true,
        inEquals = inEquals ?? true;

  const EqualityKey.exclude([bool exclude = true]) : this(inHash: !exclude, inEquals: !exclude);

  Map<String, Object?> toJson() {
    return {
      "inHash": inHash,
      "inEquals": inEquals,
    };
  }
}
