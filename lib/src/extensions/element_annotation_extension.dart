import 'package:analyzer/dart/element/element.dart';

extension ElementAnnotationExtension on ElementAnnotation {
  bool isOfType(Element classType) {
    return computeConstantValue()?.type?.element == classType;
  }
}
