import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' hide Style;
import 'package:style_generator/src/data/annotated_element.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import 'package:style_generator/src/data/variable.dart';
import 'package:style_generator/src/extensions/dart_type_extension.dart';
import 'package:style_generator/src/extensions/element_annotation_extension.dart';
import 'package:style_generator/style_generator.dart';

part '_copy_with_gen.dart';

part '_lerp_gen.dart';

part '_merge_gen.dart';

part '_of_gen.dart';

class BuilderState with _LerpGen, _MergeGen, _CopyWithGen, _OfGen {
  static final String _nl = Platform.lineTerminator;

  String generateForAnnotation(
    AssetId inputId,
    LibraryElement lib,
    AnnotationBuilder<Style> styleAnnotation,
    AnnotationBuilder<StyleKey> styleKeyAnnotation,
  ) {
    AnnotatedElement<Style> c = _getAnnotatedElements(lib.classes, styleAnnotation).first;
    ClassElement clazz = c.element as ClassElement;

    ConstructorElement? constructor = _getConstructor(clazz.constructors, c.annotation.constructor);

    if (constructor == null) throw Exception("No Constructor found");

    // List<FieldElement> fields = _getFields(clazz.fields);
    // List<Variable> variables = fields.map((e) => Variable(element: e)).toList();

    List<Variable> constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    List<Variable> fields = _getFields(clazz.fields).map((e) => Variable(element: e)).toList();

    List<AnnotatedElement<StyleKey>> v = _getAnnotatedElements(_getFields(clazz.fields), styleKeyAnnotation);

    // TODO(Alex): make StyleKey.functionCall internal or create an internal style_key representation.
    // TODO(Alex): apply annotations from constructor and from fields
    // TODO(Alex): create ThemeLerp override annotation
    v.forEach((element) => print(element.annotation.toJson()));

    VariableState state = VariableState(constructorParams: constructorParams, fields: fields);
    state.build(styleKeyAnnotation);
    List<Variable> variables = state.merged;

    Style config = c.annotation;
    String constructorName = config.constructor ?? constructor.name!;
    String? fallback = config.fallback;
    bool genCopyWith = config.genCopyWith;
    bool genMerge = config.genMerge;
    bool genLerp = config.genLerp;

    String fieldContent = _generateFieldGetter(variables);
    String ofContent = fallback == null ? "" : _generateOf(clazz.displayName, fallback);
    String copyWithContent = !genCopyWith ? "" : _generateCopyWith(clazz.displayName, constructorName, variables);
    String mergeContent = !genMerge ? "" : _generateMerge(lib, clazz.displayName, variables);
    String lerpContent = !genLerp ? "" : _generateLerp(lib, clazz.displayName, constructorName, variables);

    return _generatePartClass(
      basename(inputId.path),
      clazz.displayName,
      fields: fieldContent,
      of: ofContent,
      copyWith: copyWithContent,
      merge: mergeContent,
      lerp: lerpContent,
      trailing: [_durationLerp],
    );
  }

  String _generatePartClass(
    String filename,
    String className, {
    required String fields,
    required String of,
    required String copyWith,
    required String merge,
    required String lerp,
    List<String> trailing = const [],
  }) {
    String partClass =
        """
    part of "$filename";
    
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

  List<AnnotatedElement<T>> _getAnnotatedElements<T>(List<Element> elements, AnnotationBuilder<T> builder) {
    List<AnnotatedElement<T>> list = [];

    for (var e in elements) {
      for (var annotationClass in e.metadata.annotations) {
        if (annotationClass.isOfType(builder.annotationClass)) {
          DartObject? annotationObject = annotationClass.computeConstantValue()!;

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
      if (name == "") name = "new"; // Default Constructor name

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

  String _generateFieldGetter(List<Variable> fields) {
    List<String> f = [];

    String? name;
    for (var field in fields) {
      name = field.name;

      f.add("${field.type} get $name;");
    }

    String content =
        """
    ${f.join(_nl)}
    """;

    return content;
  }
}
