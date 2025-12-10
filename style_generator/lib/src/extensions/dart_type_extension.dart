import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/nullability_suffix.dart";
import "package:analyzer/dart/element/type.dart";

import "../data/class_method.dart";

extension DartTypeExtension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;

  bool get isDartCore =>
      isBottom ||
      isDartAsyncFuture ||
      isDartAsyncFutureOr ||
      isDartAsyncStream ||
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreEnum ||
      isDartCoreFunction ||
      isDartCoreInt ||
      isDartCoreIterable ||
      isDartCoreList ||
      isDartCoreMap ||
      isDartCoreNull ||
      isDartCoreNum ||
      isDartCoreObject ||
      isDartCoreRecord ||
      isDartCoreSet ||
      isDartCoreString ||
      isDartCoreSymbol ||
      isDartCoreType;
}

extension InterfaceTypeExtension on InterfaceType {
  ClassMethod? findMethod(LibraryElement lib, String name) {
    MethodElement? m = element.lookUpMethod(library: lib, name: name);

    if (m == null) return null;

    return ClassMethod(type: this, element: m);
  }
}
