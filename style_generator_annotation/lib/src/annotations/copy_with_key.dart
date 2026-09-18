import "package:meta/meta_meta.dart";

/// override the generation behavior of a field
///
/// - Annotations on constructor parameters take precedence over fields
/// - Annotations on fields are inherited in subclasses, while those on parameters are not
/// Example:
/// ```dart
/// @CopyWith(asExtension: false)
/// class Profile {
///   final String firstname;
///   @CopyWithKey(inCopyWith: false)
///   final String lastname;
///
///   final DateTime? birthday;
///
///   const Profile({
///     @CopyWithKey(inCopyWith: false)
///     this.firstname = "",
///     this.lastname = "",
///     this.birthday
///   });
/// }
///
///
/// @CopyWith(asExtension: true)
/// class UserProfile extends Profile {
///   final String id;
///
///   UserProfile({this.id = "", super.lastname, super.birthday, super.firstname});
/// }
/// ```
/// This generates:
/// - the `lastname` field is inherited 'as is', this also inherits its annotations.
/// - the `firstname` field is also inherited 'as is', but the annotation is on the constructor parameter and therefor not inherited with the field.
/// ```dart
/// extension $ProfileExtension on Profile {
///   Profile copyWith({
///     // String? firstname,
///     // String? lastname,
///     DateTime? birthday,
///   }) {
///     return Profile.new(
///       // firstname: firstname ?? this.firstname,
///       // lastname: lastname ?? this.lastname,
///       birthday: birthday ?? this.birthday,
///     );
///   }
/// }
///
/// extension $UserProfileExtension on UserProfile {
///   UserProfile copyWith({
///     String? id,
///     // String? lastname,
///     DateTime? birthday,
///     String? firstname,
///   }) {
///     return UserProfile.new(
///       id: id ?? this.id,
///       // lastname: lastname ?? this.lastname,
///       birthday: birthday ?? this.birthday,
///       firstname: firstname ?? this.firstname,
///     );
///   }
/// }
/// ```
@Target({
  TargetKind.field,
  TargetKind.parameter,
  TargetKind.optionalParameter,
  TargetKind.getter,
  TargetKind.overridableMember,
})
class CopyWithKey {
  /// if false, the field will not be included in the copyWith() method
  /// effectively resetting the field to the default value with each copyWith() call
  ///
  /// defaults to true
  final bool inCopyWith;

  /// if true, the field will not be changeable in the copyWith() method
  /// preserving the first value that was ever set.
  ///
  /// This is useful for fields that contain generated IDs.
  ///
  /// defaults to false
  final bool unmodifiable;

  /// The field that should be used as the fallback in the copyWith() method
  ///
  /// Example:
  /// ```dart
  /// @CopyWith()
  /// class Profile {
  ///   final String _privateOne;
  ///   final String _privateTwo;
  ///
  ///   Profile({
  ///     @CopyWithKey(field: "_privateOne")
  ///     String? private,
  ///   }) : _privateOne = private ?? "one", _privateTwo = private ?? "two";
  /// }
  /// ```
  ///
  /// This is necessary, when a constructor parameter is used to assign multiple fields.
  ///
  /// In probably every case, this can be avoided (e.g. using a factory constructor or using getter methods instead).
  ///
  /// Do only set this when the annotation is used on a constructor parameter
  final String? field;

  const CopyWithKey({
    bool? inCopyWith,
    bool? unmodifiable,
    this.field,
  })  : inCopyWith = inCopyWith ?? true,
        unmodifiable = unmodifiable ?? false;

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
      "unmodifiable": unmodifiable,
      "field": field,
    };
  }
}
