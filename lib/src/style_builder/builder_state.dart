

import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' hide Style;
import 'package:style_generator/src/data/annotated_element.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import 'package:style_generator/src/data/variable.dart';
import 'package:style_generator/src/extensions/dart_type_extension.dart';
import 'package:style_generator/src/extensions/element_extension.dart';
import 'package:style_generator/src/style_builder/style_builder.dart' ;

import '../annotations/style.dart';

part '_copy_with_gen.dart';
part '_lerp_gen.dart';
part '_merge_gen.dart';

class BuilderState with _LerpGen, _MergeGen, _CopyWithGen {

  static final String _nl = Platform.lineTerminator;

  String generateForAnnotation(AssetId inputId, LibraryElement lib, AnnotationBuilder<Style> annotation) {

    AnnotatedElement<Style> c = _getAnnotatedElements(lib.classes, annotation).first;
    ClassElement clazz = c.element as ClassElement;

    ConstructorElement constructor = _getPrimaryConstructor(clazz.constructors);

    List<FieldElement> fields = _getFields(clazz.fields);
    List<Variable> variables = fields.map((e) => Variable(element: e)).toList();

    String fieldContent = _generateFieldGetter(fields);
    String copyWithContent = _generateCopyWith(clazz.displayName, variables);
    String mergeContent = _generateMerge(lib, clazz.displayName, variables);
    String lerpContent = _generateLerp(lib, clazz.displayName, variables);

    return _generatePartClass(
        basename(inputId.path), clazz.displayName, fields: fieldContent, copyWith: copyWithContent, merge: mergeContent, lerp: lerpContent, trailing: [
      _durationLerp,
    ]);
  }

  String _generatePartClass(String filename, String className, {required String fields, required String copyWith, required String merge, required String lerp, List<String> trailing = const []}) {
    String partClass = """
    part of "$filename";
    
    mixin _\$$className {

      $fields

      $copyWith
      
      $merge
      
      $lerp
      
      ${trailing.join("$_nl$_nl")}
    }
    """;

    return partClass;
  }

  List<AnnotatedElement<T>> _getAnnotatedElements<T>(List<Element> elements, AnnotationBuilder<T> builder) {
    List<AnnotatedElement<T>> list = [];

    for (var e in elements) {
      for (var annotationClass in e.metadata.annotations) {
        if (annotationClass.isOfType(builder.annotationClass)) {
          
          DartObject? annotationObject = annotationClass.computeConstantValue()!;
          
          list.add(AnnotatedElement<T>(
            element: e,
            object: annotationObject,
            annotation: builder.build(annotationObject),
          ));
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

  void print(Object? text) {
    log.log(Level.WARNING, text);
  }

  String _generateFieldGetter(List<FieldElement> fields) {
    List<String> f = [];

    String? name;
    for (var field in fields) {
      name = field.name;

      f.add("${field.type} get $name;");
    }


    String content = """
    ${f.join(_nl)}
    """;

    return content;
  }


}



