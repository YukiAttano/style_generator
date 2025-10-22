import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

class AnnotatedElement<T> {
  final Element element;

  /// the object that represents the annotation found on [element].
  ///
  /// This was used to create [annotation]
  final DartObject object;

  /// an object of the annotation type.
  ///
  /// this can be used to read the configuration
  final T annotation;

  const AnnotatedElement({required this.element, required this.object, required this.annotation});
}
