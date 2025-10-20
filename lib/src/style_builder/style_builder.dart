import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'package:source_gen/source_gen.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import 'package:style_generator/src/style_builder/builder_state.dart';

import '../../style_generator.dart';



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

  bool _isInitialized = false;

  final Map<String, AnnotationBuilder> _libraryAnnotations = {};
  AnnotationBuilder<Style> get styleAnnoBuilder => _libraryAnnotations["Style"] as AnnotationBuilder<Style>;

  Future<void> _init(BuildStep buildStep) async {
    var asset = AssetId.resolve(Uri.parse("package:style_generator/style_generator.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);

    ClassElement? styleElement = lib.exportNamespace.get2("Style") as ClassElement?;
    if (styleElement != null) {
      _libraryAnnotations["Style"] = AnnotationBuilder<Style>(annotationClass: styleElement, buildAnnotation: Style.fromJson);
    }
    _isInitialized = true;
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

    String partClass = state.generateForAnnotation(inputId, l, styleAnnoBuilder);

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}
