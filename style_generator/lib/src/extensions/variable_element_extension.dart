import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";

import "../data/logger.dart";
import "dart_type_extension.dart";

extension VariableElementExtension on VariableElement {
  bool isOfSameTypeAsTypeArgumentFromObject(DartObject object, {bool? lessStrict, bool? allowDynamic}) {
    DartType? type = object.type;
    if (type == null) {
      hasNoType(object);
      return false;
    }

    return isOfSameTypeAsTypeArgumentFrom(
      type.extensionTypeErasure,
      allowDynamic: allowDynamic,
      lessStrict: lessStrict,
    );
  }

  /// returns true if this and the first argument type of [type] are same
  ///
  /// The first type argument of [type] will be further referenced as `argument`
  ///
  /// ```txt
  /// this = Color
  /// type = StyleKey<Color>
  ///
  /// (returns true)
  /// ```
  ///
  /// if [lessStrict] is true, `this` may be nullable while `argument` is not
  /// ```txt
  /// this = Color?
  /// type = StyleKey<Color>
  ///
  /// (returns true)
  ///
  ///
  /// this = Color
  /// type = StyleKey<Color?>
  ///
  /// (returns false)
  /// ```
  ///
  /// if [allowDynamic] is true, `argument` can be `dynamic`
  bool isOfSameTypeAsTypeArgumentFrom(DartType type, {bool? lessStrict, bool? allowDynamic}) {
    lessStrict ??= false;
    allowDynamic ??= false;

    if (type is! InterfaceType) {
      typeIsNotSubtypeOfInterfaceType(type);
      return false;
    }

    DartType? argument = type.typeArguments.firstOrNull?.extensionTypeErasure;
    if (argument == null) {
      typeHasNoTypeArguments(type);
      return false;
    }

    if (argument is DynamicType && allowDynamic) return true;

    bool typesAreEqual = this.type == argument;
    bool elementsAreEqual = this.type.element == argument.element;

    if (lessStrict) {
      // return true if both have the same
      // for Type? == Argument? and Type? == Argument
      bool thisIsNullable = this.type.isNullable;
      bool sameNullability = thisIsNullable == argument.isNullable;
      bool argumentIsMoreStrict = thisIsNullable && !argument.isNullable;

      return (sameNullability && typesAreEqual) || (argumentIsMoreStrict && elementsAreEqual);
    } else {
      return typesAreEqual && elementsAreEqual;
    }
  }
}
