import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/copy_with_generator_annotation.dart";

import "../../style_generator.dart";
import "../annotations/copy_with_config.dart";
import "../annotations/copy_with_key_internal.dart";
import "../builder_mixins/copy_with_gen.dart";
import "../builder_mixins/fields_gen.dart";
import "../data/annotated_element.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/lookup_store.dart";
import "../data/variable.dart";
import "../extensions/class_element_extension.dart";
import "../extensions/element_annotation_extension.dart";
import "../extensions/string_constructor_extension.dart";

class CopyWithGeneratorResult {
  final bool addPartDirective;
  final List<String> parts;

  bool get isEmpty => parts.isEmpty;

  const CopyWithGeneratorResult({required this.addPartDirective, required this.parts});
}

class _GenResult {
  final bool addPartDirective;
  final String part;

  const _GenResult({required this.addPartDirective, required this.part});
}

class CopyWithGenerator with FieldsGen, CopyWithGen {
  static String get _nl => newLine;

  LibraryElement get libElement => resolvedLib.element;
  final ResolvedLibraryResult resolvedLib;
  final CopyWithConfig copyWithConfig;
  final LookupStore store;

  AnnotationConverter<CopyWith> get copyWithAnnotation => store.copyWithAnnoConverter;

  AnnotationConverter<CopyWithKeyInternal> get copyWithKeyAnnotation => store.copyWithKeyAnnoConverter;

  CopyWithGenerator({
    required this.resolvedLib,
    required this.copyWithConfig,
    required this.store,
  });

  CopyWithGeneratorResult generate() {
    List<AnnotatedElement<CopyWith>> classes = _getAnnotatedElements(libElement.classes, copyWithAnnotation);

    bool addPartDirective = false;
    List<String> parts = [];

    _GenResult result;
    CopyWithConfig config;
    for (var c in classes) {
      config = copyWithConfig.apply(c.annotation);

      result = _generateForClass(c, config);

      addPartDirective = addPartDirective || result.addPartDirective;
      parts.add(result.part);
    }

    return CopyWithGeneratorResult(addPartDirective: addPartDirective, parts: parts);
  }

  _GenResult _generateForClass(AnnotatedElement<CopyWith> annotatedClazz, CopyWithConfig config) {
    ClassElement clazz = annotatedClazz.element as ClassElement;
    ConstructorElement? constructor = _getConstructor(clazz.constructors, config.constructor?.asConstructorName);

    if (constructor == null) throw Exception("No Constructor found");

    List<Variable> constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    List<Variable> fields = clazz.getPropertyFields().map((e) => Variable(element: e)).toList();

    VariableHandler state = VariableHandler(constructorParams: constructorParams, fields: fields);
    state.build(copyWithKeyAnnotation);
    state.resolveTypes(resolvedLib);

    List<Variable> variables = state.merged;

    String constructorName = (config.constructor ?? constructor.name!).asConstructorName;
    bool asExtension = config.asExtension ?? false;
    bool genFields = !asExtension;
    String suffix = config.suffix;

    String generatedClassName = clazz.displayName + suffix;
    String fieldContent = !genFields ? "" : generateFieldGetter(variables);
    String copyWithContent = generateCopyWith(
      clazz.displayName,
      constructorName,
      variables,
      (v) => v.getAnnotationOf(copyWithKeyAnnotation)?.inCopyWith,
    );

    return _GenResult(
      addPartDirective: !asExtension,
      part: _generatePartClass(
        generatedClassName,
        clazz.displayName,
        fields: fieldContent,
        copyWith: copyWithContent,
        copyWithAsExtension: asExtension,
      ),
    );
  }

  String _generateMixin(String generatedClassName, {required String fields, required String copyWith}) {
    return """
      mixin _\$$generatedClassName {
      
        $fields
        
        $copyWith
      }
    """;
  }

  String _generateExtension(String generatedClassName, String className, {required String copyWith}) {
    return """
      extension \$${generatedClassName}Extension on $className {
        $copyWith
      }
    """;
  }

  String _generatePartClass(
    String generatedClassName,
    String className, {
    required String fields,
    required String copyWith,
    required bool copyWithAsExtension,
    List<String> trailing = const [],
  }) {
    String partClass;
    String mixin;
    String extension;
    bool hasMixin = !copyWithAsExtension || trailing.isNotEmpty;

    mixin = _generateMixin(generatedClassName, fields: fields, copyWith: copyWith);
    extension = _generateExtension(generatedClassName, className, copyWith: copyWith);

    partClass = """
       
    ${hasMixin ? mixin : ""}

    ${copyWithAsExtension ? extension : ""}

    """;

    return partClass;
  }

  List<AnnotatedElement<T>> _getAnnotatedElements<T>(List<Element> elements, AnnotationConverter<T> builder) {
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

  ConstructorElement? _getConstructor(List<ConstructorElement> constructors, String? name) {
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
