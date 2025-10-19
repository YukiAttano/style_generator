

import 'package:analyzer/dart/element/element.dart';

extension ElementExtension on ElementAnnotation {

  bool isOfType(Element classType) {
    return computeConstantValue()?.type?.element == classType;
  }

  bool isOfTypeFromString(LibraryElement lib, String annotationClazz) {
    Element? clazzElement = lib.exportNamespace.get2(annotationClazz);

    return computeConstantValue()?.type?.element == clazzElement;
  }
}