
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

typedef AnnotationFromJson<T> = T Function(Map<String, Object?> json);

class AnnotationBuilder<T> {
  /// the annotation as class element (e.g. @Style() annotation)
  final ClassElement annotationClass;
  final AnnotationFromJson<T> _buildAnnotation;

  const AnnotationBuilder({required this.annotationClass, required AnnotationFromJson<T> buildAnnotation}) : _buildAnnotation = buildAnnotation;

  T build(DartObject object)  {
    Map<String, Object?> json = {};

    for (var f in annotationClass.fields) {
      json[f.displayName] = object.getField(f.displayName);
    }

    return _buildAnnotation(json);
  }
}