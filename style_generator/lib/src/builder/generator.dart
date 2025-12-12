import "dart:async";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/src/dart/ast/ast.dart";
import "package:build/build.dart";
import "package:meta/meta.dart";

import "../data/annotated_element.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/lookup_store.dart";
import "../data/variable.dart";
import "../extensions/element/class_element_extension.dart";
import "../extensions/element_annotation_extension.dart";
import "../extensions/resolved_library_result_extension.dart";
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

  final Resolver resolver;
  LibraryElement get libElement => resolvedLib.element;
  final ResolvedLibraryResult resolvedLib;
  final LookupStore store;

  AnnotationConverter<A> get annotation;
  AnnotationConverter<K>? get keyAnnotation;

  final C config;

  Generator({
    required this.resolver,
    required this.resolvedLib,
    required this.store,
    required this.config,
  });

  @protected
  Future<GeneratorResult> generate() async {
    List<AnnotatedElement<A>> classes = getAnnotatedElements(libElement.classes, annotation);

    List<PartGenResult> parts = [];

    PartGenResult result;
    C conf;
    for (var c in classes) {
      conf = config.apply(c.annotation) as C;

      result = await generateForClass(c, conf);

      parts.add(result);
    }

    return mergeParts(parts);
  }

  Future<PartGenResult> generateForClass(AnnotatedElement<A> annotatedClazz, C config);

  GeneratorResult mergeParts(List<PartGenResult> parts);

  Future<AnalyzedClass> analyzeClass(AnnotatedElement<A> annotatedClazz, String? constructorName) async {
    ClassElement clazz = annotatedClazz.element as ClassElement;
    ConstructorElement? constructor = findConstructor(clazz.constructors, constructorName);

    if (constructor == null) throw Exception("No Constructor found");

    VariableHandler state = VariableHandler(clazz: clazz, constructor: constructor);
    state.mapParameterToFields(resolvedLib);
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
