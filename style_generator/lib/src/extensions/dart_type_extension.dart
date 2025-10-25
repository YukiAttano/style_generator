import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/nullability_suffix.dart";
import "package:analyzer/dart/element/type.dart";
import "package:collection/collection.dart";

import "../data/method.dart";

extension DartTypeExtension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;
}

extension InterfaceTypeExtension on InterfaceType {
  ClassMethod? findMethod(String name) {
    MethodElement? m = element.methods.firstWhereOrNull((m) => m.name == name);

    if (m == null) return null;

    return ClassMethod(type: this, element: m);
  }
}
