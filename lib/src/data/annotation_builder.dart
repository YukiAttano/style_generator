
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

typedef AnnotationFromMap<T> = T Function(Map<String, DartObject?> map);

class AnnotationBuilder<T> {
  /// the annotation as class element (e.g. @Style() annotation)
  final ClassElement annotationClass;
  final AnnotationFromMap<T> _buildAnnotation;

  const AnnotationBuilder({required this.annotationClass, required AnnotationFromMap<T> buildAnnotation}) : _buildAnnotation = buildAnnotation;

  T build(DartObject object)  {
    Map<String, DartObject?> map = {};

    for (var f in annotationClass.fields) {
      DartObject? field = object.getField(f.displayName);

      map[f.displayName] = field;
    }

    return _buildAnnotation(map);
  }
}
