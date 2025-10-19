

import 'dart:io';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' hide Style;
import 'package:style_generator/src/data/variable.dart';
import 'package:style_generator/src/extensions/element_extension.dart';
import 'package:style_generator/src/style_builder/style_builder.dart' ;
import 'package:logging/logging.dart';

part '_lerp_gen.dart';
part '_merge_gen.dart';
part '_copy_with_gen.dart';

class BuilderState with _LerpGen, _MergeGen, _CopyWithGen {

  static final String _nl = Platform.lineTerminator;

  String generateForAnnotation(AssetId inputId, LibraryElement lib, Element annotation) {

    ClassElement clazz = _getAnnotatedClasses(lib, annotation).first;

    ConstructorElement constructor = _getPrimaryConstructor(clazz.constructors);

    List<FieldElement> fields = _getFields(clazz.fields);

    String fieldContent = _generateFieldGetter(fields);
    String copyWithContent = _generateCopyWith(clazz.displayName, fields);
    String mergeContent = _generateMerge(lib, clazz.displayName, fields);
    String lerpContent = _generateLerp(lib, clazz.displayName, fields.map((e) => Variable(element: e)).toList());

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

  List<ClassElement> _getAnnotatedClasses(LibraryElement lib, Element annotation) {
    List<ClassElement> classes = [];

    for (var c in lib.classes) {
      for (var a in c.metadata.annotations) {
        if (a.isOfType(annotation)) {
          classes.add(c);
        }
      }
    }

    return classes;
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



