import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../../style_generator.dart";
import "../annotations/style_config.dart";
import "../annotations/style_key_internal.dart";
import "../builder_mixins/copy_with_gen.dart";
import "../builder_mixins/fields_gen.dart";
import "../builder_mixins/lerp_gen.dart";
import "../builder_mixins/merge_gen.dart";
import "../builder_mixins/of_gen.dart";
import "../data/annotated_element.dart";
import "../data/annotation_converter.dart";
import "../data/lookup_store.dart";
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

  LibraryElement get libElement => resolvedLib.element;
  final ResolvedLibraryResult resolvedLib;
  final StyleConfig styleConfig;
  final LookupStore store;

  AnnotationConverter<Style> get styleAnnotation => store.styleAnnoConverter;

  AnnotationConverter<StyleKeyInternal> get styleKeyAnnotation => store.styleKeyAnnoConverter;

  StyleGenerator({
    required this.resolvedLib,
    required this.styleConfig,
    required this.store,
  });

  StyleGeneratorResult generate() {
    List<AnnotatedElement<Style>> classes = _getAnnotatedElements(libElement.classes, styleAnnotation);

    List<String> parts = [];

    StyleConfig config;
    for (var c in classes) {
      config = styleConfig.apply(c.annotation);

      if (config.isDisabled) continue;

      parts.add(
        _generateForClass(c, config),
      );
    }

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
    state.resolveTypes(resolvedLib);

    List<Variable> variables = state.merged;

    ConstructorElement? fallbackConstructor = _getConstructor(clazz.constructors, config.fallback);
    ConstructorElement? ofConstructor = _getConstructor(clazz.constructors, "of");

    Variable? buildContext = _getBuildContextParameterFrom(fallback: fallbackConstructor, of: ofConstructor);

    String constructorName = (config.constructor ?? constructor.name!).asConstructorName;
    String fallback = (config.fallback ?? "").asConstructorName;
    bool genFields = config.genFields;
    bool genCopyWith = config.genCopyWith;
    bool genMerge = config.genMerge;
    bool genLerp = config.genLerp;
    bool genOf = config.genOf ?? buildContext != null;
    String suffix = config.suffix;

    String generatedClassName = clazz.displayName + suffix;
    String fieldContent = !genFields ? "" : generateFieldGetter(variables);
    String ofContent = !genOf ? "" : generateOf(clazz.displayName, suffix, buildContext, fallback);
    String copyWithContent =
        !genCopyWith ? "" : generateCopyWith(clazz.displayName, constructorName, variables, styleKeyAnnotation);
    String mergeContent = !genMerge ? "" : generateMerge(resolvedLib, clazz.displayName, variables, styleKeyAnnotation);
    LerpGenResult lerpContent = !genLerp
        ? const LerpGenResult()
        : generateLerp(resolvedLib, clazz.displayName, constructorName, variables, styleKeyAnnotation);

    return _generatePartClass(
      generatedClassName,
      fields: fieldContent,
      of: ofContent,
      copyWith: copyWithContent,
      merge: mergeContent,
      lerp: lerpContent.content,
      trailing: [...lerpContent.trailing],
    );
  }

  Variable? _getBuildContextParameterFrom({ConstructorElement? fallback, ConstructorElement? of}) {
    if (fallback == null || of == null) return null;

    List<FormalParameterElement> params = fallback.formalParameters;

    if (params.isNotEmpty) {
      // if our first parameter is positional, it must be of type BuildContext because we cannot pass other arguments
      // into our fallback constructor
      FormalParameterElement p = params.first;
      if (p.isPositional) {
        if (p.type == store.buildContextType) {
          return Variable(element: p, fieldElement: null);
        } else {
          return null;
        }
      }

      // if the first is not positional, none will be positional so we can search for our fitting parameter.
      // we do not check if other parameter are required, so we might still generate a broken of() constructor.
      // This is fine, because the dart analyzer will tell the user whats wrong
      for (var p in params) {
        if (p.type == store.buildContextType) {
          return Variable(element: p, fieldElement: null);
        }
      }
    }

    return null;
  }

  String _generatePartClass(
    String generatedClassName, {
    required String fields,
    required String of,
    required String copyWith,
    required String merge,
    required String lerp,
    List<String> trailing = const [],
  }) {
    String partClass = """
       
    mixin _\$$generatedClassName {

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
