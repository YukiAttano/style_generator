import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:style_generator/src/extensions/element_annotation_extension.dart';

import '../data/annotated_element.dart';
import '../data/annotation_converter.dart';

extension ElementExtension on Element {
  List<AnnotatedElement<T>> getAnnotationsOf<T>(AnnotationConverter<T> converter) {
    List<AnnotatedElement<T>> list = [];

    for (var annotationClass in metadata.annotations) {
      if (annotationClass.isOfType(converter.annotationClass)) {
        DartObject? annotationObject = annotationClass.computeConstantValue()!;

        list.add(
          AnnotatedElement<T>(element: this, object: annotationObject, annotation: converter.build(annotationObject)),
        );
      }
    }

    return list;
  }
}
