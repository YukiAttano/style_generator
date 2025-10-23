import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:path/path.dart" hide Style;
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../../style_generator.dart";
import "../annotations/style_config.dart";
import "../annotations/style_key_internal.dart";
import "../builder_mixins/copy_with_gen.dart";
import "../builder_mixins/fields_gen.dart";
import "../builder_mixins/header_gen.dart";
import "../builder_mixins/lerp_gen.dart";
import "../builder_mixins/merge_gen.dart";
import "../builder_mixins/of_gen.dart";
import "../data/annotated_element.dart";
import "../data/annotation_converter.dart";
import "../data/variable.dart";
import "../extensions/element_annotation_extension.dart";
import "../extensions/string_constructor_extension.dart";

class StyleGeneratorResult {
  final List<String> parts;

  bool get isEmpty => parts.isEmpty;

  const StyleGeneratorResult({required this.parts});
}

class StyleGenerator with FieldsGen, LerpGen, MergeGen, CopyWithGen, OfGen {
  static String get _nl => newLine;

  final LibraryElement lib;
  final StyleConfig styleConfig;
  final AnnotationConverter<Style> styleAnnotation;
  final AnnotationConverter<StyleKeyInternal> styleKeyAnnotation;

  StyleGenerator({
    required this.lib,
    required this.styleConfig,
    required this.styleAnnotation,
    required this.styleKeyAnnotation,
  });

  StyleGeneratorResult generate() {
    List<AnnotatedElement<Style>> classes = _getAnnotatedElements(lib.classes, styleAnnotation);

    List<String> parts = [];

    StyleConfig config;
    for (var c in classes) {
      config = styleConfig.apply(c.annotation);

      if (config.isDisabled) continue;

      parts.add(
        _generateForClass(c, config),
      );
    }

    print("GEN ${parts.length}");

    return StyleGeneratorResult(parts: parts);
  }

  String _generateForClass(AnnotatedElement<Style> annotatedClazz, StyleConfig config) {
    ClassElement clazz = annotatedClazz.element as ClassElement;
    ConstructorElement? constructor = _getConstructor(clazz.constructors, config.constructor?.asConstructorName);

    if (constructor == null) throw Exception("No Constructor found");

    List<Variable> constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    List<Variable> fields = _getFields(clazz.fields).map((e) => Variable(element: e)).toList();

    VariableHandler state = VariableHandler(constructorParams: constructorParams, fields: fields);
    state.build(styleKeyAnnotation);

    List<Variable> variables = state.merged;

    if (variables.isEmpty) throw Exception("Empty Class");

    String constructorName = (config.constructor ?? constructor.name!).asConstructorName;
    String fallback = (config.fallback ?? "").asConstructorName;
    bool genFields = config.genFields;
    bool genCopyWith = config.genCopyWith;
    bool genMerge = config.genMerge;
    bool genLerp = config.genLerp;
    bool genOf = config.genOf;

    String fieldContent = !genFields ? "" : generateFieldGetter(variables);
    String ofContent = !genOf ? "" : generateOf(clazz.displayName, fallback);
    String copyWithContent =
        !genCopyWith ? "" : generateCopyWith(clazz.displayName, constructorName, variables, styleKeyAnnotation);
    String mergeContent = !genMerge ? "" : generateMerge(lib, clazz.displayName, variables, styleKeyAnnotation);
    LerpGenResult lerpContent = !genLerp
        ? const LerpGenResult()
        : generateLerp(lib, clazz.displayName, constructorName, variables, styleKeyAnnotation);

    return _generatePartClass(
      clazz.displayName,
      fields: fieldContent,
      of: ofContent,
      copyWith: copyWithContent,
      merge: mergeContent,
      lerp: lerpContent.content,
      trailing: [...lerpContent.trailing],
    );
  }

  String _generatePartClass(
    String className, {
    required String fields,
    required String of,
    required String copyWith,
    required String merge,
    required String lerp,
    List<String> trailing = const [],
  }) {
    String partClass = """
       
    mixin _\$$className {

      $fields
      
      $copyWith
      
      $merge
      
      $lerp
      
      ${trailing.join("$_nl$_nl")}
    }

    $of 
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

  List<FieldElement> _getFields(List<FieldElement> fields) {
    List<FieldElement> list = [];

    for (var f in fields) {
      if (f.isStatic || f.isSynthetic || f.isPrivate) {
        continue;
      }

      list.add(f);
    }

    return list;
  }

  ConstructorElement? _getConstructor(List<ConstructorElement> constructors, String? name) {
    ConstructorElement? constructor;

    if (name == null) {
      constructor = _getPrimaryConstructor(constructors);
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

  ConstructorElement _getPrimaryConstructor(List<ConstructorElement> constructors) {
    ConstructorElement? primaryConstructor;

    for (var c in constructors) {
      if (primaryConstructor == null) {
        primaryConstructor = c;
      } else if (c.isPublic) {
        if (primaryConstructor.isPrivate) {
          primaryConstructor = c;
        }
      }
    }

    return primaryConstructor!;
  }
}
