import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';
import 'package:source_gen/source_gen.dart';
import 'package:style_generator/src/style_builder/builder_state.dart';

class Style {
  const Style();
}

/*
    // Lookup classes from packages
    var asset = AssetId.resolve(Uri.parse("package:flutter/material.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);
    print(lib.exportNamespace.get2("ThemeExtension"));

 */

class SomeGen extends GeneratorForAnnotation {

}

class StyleBuilder implements Builder {

  @override
  final buildExtensions = const {
    '.dart': ['.style.dart']
  };


  Iterable<DartObject> _annotationsWhere(
      Object element,
      bool Function(DartType) predicate, {
        bool throwOnUnresolved = true,
      }) sync* {
    if (element
    case Element(:final metadata) || ElementDirective(:final metadata)) {
      final annotations = metadata.annotations;
      for (var i = 0; i < annotations.length; i++) {
        final value = annotations[i].computeConstantValue();
        if (value?.type != null && predicate(value!.type!)) {
          yield value;
        }
      }
    }
  }

  bool isAssignableFromType(DartType staticType) {
    final element = staticType.element;
    return element != null && isAssignableFrom(element);
  }

  bool isAssignableFrom(Element element) =>

          (element is InterfaceElement && element.allSupertypes.any(isExactlyType));

  bool isExactlyType(DartType staticType) {
    final element = staticType.element;
    if (element != null) {
      return true;
    } else {
      return false;
    }
  }

  bool _isInitialized = false;

  final Map<String, Element> _libraryAnnotations = {};
  Element get styleAnnotation => _libraryAnnotations["Style"]!;

  Future<void> _init(BuildStep buildStep) async {
    var asset = AssetId.resolve(Uri.parse("package:style_generator/style_generator.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);

    Element? styleElement = lib.exportNamespace.get2("Style");
    if (styleElement != null) _libraryAnnotations["Style"] = styleElement;
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!_isInitialized) await _init(buildStep);

    DartFormatter formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

    // Create the output ID from the build step input ID.
    AssetId inputId = buildStep.inputId;
    AssetId outputId = inputId.changeExtension('.style.dart');

    var l = await buildStep.inputLibrary;


    BuilderState state = BuilderState();

    String partClass = state.generateForAnnotation(inputId, l, styleAnnotation);

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}





extension DartTypeExtension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;
}