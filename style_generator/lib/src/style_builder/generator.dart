import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";

import "../data/annotated_element.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/lookup_store.dart";
import "../data/variable.dart";
import "../extensions/class_element_extension.dart";
import "../extensions/element_annotation_extension.dart";
import "config.dart";

class GeneratorResult {
  final List<String> parts;

  bool get isEmpty => parts.isEmpty;

  const GeneratorResult({required this.parts});
}

class PartGenResult {
  final String part;

  const PartGenResult({required this.part});
}

class AnalyzedClass {
  final ClassElement clazz;
  final ConstructorElement constructor;
  final VariableHandler variableHandler;

  List<Variable> get constructorParams => variableHandler.constructorParams;

  List<Variable> get fields => variableHandler.fields;

  List<Variable> get variables => variableHandler.merged;

  const AnalyzedClass({
    required this.clazz,
    required this.constructor,
    required this.variableHandler,
  });
}

/// Base class to reduce copied code between generator
///
/// - 'A' - Annotation
/// - 'K' - KeyAnnotation
/// - 'C' - Config
abstract base class Generator<A, K, C extends Config<A>> {
  LibraryElement get libElement => resolvedLib.element;
  final ResolvedLibraryResult resolvedLib;
  final LookupStore store;

  AnnotationConverter<A> get annotation;
  AnnotationConverter<K>? get keyAnnotation;

  final C config;

  Generator({
    required this.resolvedLib,
    required this.store,
    required this.config,
  });

  GeneratorResult generate() {
    List<AnnotatedElement<A>> classes = getAnnotatedElements(libElement.classes, annotation);

    List<PartGenResult> parts = [];

    PartGenResult result;
    C conf;
    for (var c in classes) {
      conf = config.apply(c.annotation) as C;

      result = generateForClass(c, conf);

      parts.add(result);
    }

    return mergeParts(parts);
  }

  PartGenResult generateForClass(AnnotatedElement<A> annotatedClazz, C config);

  GeneratorResult mergeParts(List<PartGenResult> parts);

  AnalyzedClass analyzeClass(AnnotatedElement<A> annotatedClazz, String? constructorName) {
    ClassElement clazz = annotatedClazz.element as ClassElement;
    ConstructorElement? constructor = findConstructor(clazz.constructors, constructorName);

    if (constructor == null) throw Exception("No Constructor found");

    List<Variable> constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    List<Variable> fields = clazz.getPropertyFields().map((e) => Variable(element: e)).toList();

    VariableHandler state = VariableHandler(constructorParams: constructorParams, fields: fields);
    if (keyAnnotation != null) state.build(keyAnnotation!);
    state.resolveTypes(resolvedLib);

    return AnalyzedClass(clazz: clazz, constructor: constructor, variableHandler: state);
  }

  List<AnnotatedElement<T>> getAnnotatedElements<T>(List<Element> elements, AnnotationConverter<T> builder) {
    List<AnnotatedElement<T>> list = [];

    for (var e in elements) {
      for (var annotationClass in e.metadata.annotations) {
        if (annotationClass.isOfType(builder.annotationClass)) {
          DartObject annotationObject = annotationClass.computeConstantValue()!;

          list.add(
            AnnotatedElement<T>(element: e, object: annotationObject, annotation: builder.build(annotationObject)),
          );
        }
      }
    }

    return list;
  }

  ConstructorElement? findConstructor(List<ConstructorElement> constructors, String? name) {
    ConstructorElement? constructor;

    if (name == null) {
      constructor = constructors.getPrimaryConstructor();
    } else {
      //  // ignore:  parameter_assignments .
      //  if (name == "") name = "new"; // Default Constructor name

      for (var c in constructors) {
        if (c.name == name && c.name != null) {
          constructor = c;
          break;
        }
      }
    }

    return constructor;
  }
}
