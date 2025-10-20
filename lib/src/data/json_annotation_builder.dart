
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import '../extensions/dart_object_extension.dart';

typedef AnnotationFromJson<T> = T Function(Map<String, Object?> json);

class JsonAnnotationBuilder<T> extends AnnotationBuilder<T> {
  
  final AnnotationFromJson<T> _buildAnnotation;

  const JsonAnnotationBuilder({required super.annotationClass, required AnnotationFromJson<T> buildAnnotation}) : _buildAnnotation = buildAnnotation,
  super(buildAnnotation: _empty);

  @override
  T build(DartObject object)  {
    Map<String, Object?> json = {};

    DartObject? field;
    for (var f in annotationClass.fields) {
      field = object.getField(f.displayName);

      json[f.displayName] = field?.toValue();
    }

    return _buildAnnotation(json);
  }
  
  static T _empty<T>(Map<String, DartObject?> map) => throw UnimplementedError();
}
