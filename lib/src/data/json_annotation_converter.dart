import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:style_generator/src/data/annotation_converter.dart';
import '../extensions/dart_object_extension.dart';

typedef AnnotationFromJson<T> = T Function(Map<String, Object?> json);

/// reconstructs an annotation based on a json object
class JsonAnnotationConverter<T> extends AnnotationConverter<T> {
  JsonAnnotationConverter({required super.annotationClass, required AnnotationFromJson<T> buildAnnotation})
    : super(buildAnnotation: (map) => _mapToJson(map, buildAnnotation));
}

T _mapToJson<T>(Map<String, DartObject?> map, AnnotationFromJson<T> fromJson) {
  Map<String, Object?> json = {};

  for (var f in map.entries) {
    json[f.key] = f.value?.toValue();
  }

  return fromJson(json);
}
