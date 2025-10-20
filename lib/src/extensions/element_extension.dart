import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:style_generator/src/extensions/element_annotation_extension.dart';

import '../data/annotated_element.dart';
import '../data/annotation_builder.dart';

extension ElementExtension on Element {
  List<AnnotatedElement<T>> getAnnotationsOf<T>(AnnotationBuilder<T> builder) {
    List<AnnotatedElement<T>> list = [];

    for (var annotationClass in metadata.annotations) {
      if (annotationClass.isOfType(builder.annotationClass)) {
        DartObject? annotationObject = annotationClass.computeConstantValue()!;

        list.add(
          AnnotatedElement<T>(element: this, object: annotationObject, annotation: builder.build(annotationObject)),
        );
      }
    }

    return list;
  }
}
