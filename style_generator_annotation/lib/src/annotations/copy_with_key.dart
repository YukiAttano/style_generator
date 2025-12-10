import "package:meta/meta_meta.dart";

/// override the generation behavior of a field
///
/// - Annotations on constructor parameters take precedence over fields
/// - Annotations on fields are inherited in subclasses, while those on parameters do not
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
class CopyWithKey<T> {
  /// if false, the field will not be included in the copyWith() method
  final bool inCopyWith;

  const CopyWithKey({
    bool? inCopyWith,
  }) : inCopyWith = inCopyWith ?? true;

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
    };
  }
}
