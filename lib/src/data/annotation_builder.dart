
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import '../extensions/dart_object_extension.dart';

typedef AnnotationFromJson<T> = T Function(Map<String, Object?> json);

class AnnotationBuilder<T> {
  /// the annotation as class element (e.g. @Style() annotation)
  final ClassElement annotationClass;
  final AnnotationFromJson<T> _buildAnnotation;

  const AnnotationBuilder({required this.annotationClass, required AnnotationFromJson<T> buildAnnotation}) : _buildAnnotation = buildAnnotation;

  T build(DartObject object)  {
    Map<String, Object?> json = {};

    DartObject? field;
    for (var f in annotationClass.fields) {
      field = object.getField(f.displayName);

      json[f.displayName] = field?.toValue();
    }

    return _buildAnnotation(json);
  }
}
