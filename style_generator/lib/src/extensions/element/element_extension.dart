import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../../data/annotated_element.dart";
import "../../data/annotation_converter/annotation_converter.dart";
import "../element_annotation_extension.dart";

extension ElementExtension on Element {
  List<AnnotatedElement<T>> getAnnotationsOf<T>(AnnotationConverter<T> converter) {
    List<AnnotatedElement<T>> list = [];

    for (var annotationClass in metadata.annotations) {
      if (annotationClass.isOfType(converter.annotationClass)) {
        DartObject annotationObject = annotationClass.computeConstantValue()!;

        list.add(
          AnnotatedElement<T>(element: this, object: annotationObject, annotation: converter.build(annotationObject)),
        );
      }
    }

    return list;
  }

  TypeAnnotation? getPrefixedType(ResolvedLibraryResult resolvedLib) {
    FragmentDeclarationResult? fragmentDeclaration;

    var iterator = fragments.iterator;
    while (fragmentDeclaration == null && iterator.moveNext()) {
      try {
        fragmentDeclaration = resolvedLib.getFragmentDeclaration(iterator.current);
        // ignore: avoid_catching_errors because we have to iterate over all imported libraries to find the one, where our field is getting his import from. This happens, if we have to lookup fields from a super class.
      } on ArgumentError catch (_) {
        // ignore
      }
    }

    AstNode? node = fragmentDeclaration?.node.parent;
    if (node is VariableDeclarationList) {
      return node.type;
    }

    return null;
  }

}
