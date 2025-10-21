import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:style_generator/src/data/annotation_converter.dart';
import 'package:style_generator/src/style_builder/style_generator.dart';

import '../../style_generator.dart';
import '../annotations/style_key_internal.dart';
import '../data/json_annotation_converter.dart';

/*
    // Lookup classes from packages
    var asset = AssetId.resolve(Uri.parse("package:flutter/material.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);
    print(lib.exportNamespace.get2("ThemeExtension"));

 */

String get newLine => Platform.lineTerminator;

class SomeGen extends GeneratorForAnnotation {}

class StyleBuilder implements Builder {

  static const String outExtension = ".style.dart";

  @override
  final buildExtensions = const {
    '.dart': [outExtension],
  };

  bool _isInitialized = false;

  final Map<String, AnnotationConverter> _libraryAnnotations = {};

  AnnotationConverter<Style> get styleAnnoConverter => _libraryAnnotations["Style"] as AnnotationConverter<Style>;

  AnnotationConverter<StyleKeyInternal> get styleKeyAnnoConverter => _libraryAnnotations["StyleKey"] as AnnotationConverter<StyleKeyInternal>;

  Future<void> _init(BuildStep buildStep) async {
    // create ClassElements of our annotations
    AssetId asset = AssetId.resolve(Uri.parse("package:style_generator/style_generator.dart"));
    LibraryElement lib = await buildStep.resolver.libraryFor(asset);

    ClassElement? styleElement = lib.exportNamespace.get2("Style") as ClassElement?;
    ClassElement? styleKeyElement = lib.exportNamespace.get2("StyleKey") as ClassElement?;
    // create converter for the ClassElements to read the configured Annotations from real DartObjects
    if (styleElement != null) {
      _libraryAnnotations["Style"] = JsonAnnotationConverter<Style>(
        annotationClass: styleElement,
        buildAnnotation: Style.fromJson,
      );
    }
    if (styleKeyElement != null) {
      _libraryAnnotations["StyleKey"] = AnnotationConverter<StyleKeyInternal>(
        annotationClass: styleKeyElement,
        buildAnnotation: createStyleKey,
      );
    }
    _isInitialized = true;
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!_isInitialized) await _init(buildStep);

    DartFormatter formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

    AssetId inputId = buildStep.inputId;
    AssetId outputId = inputId.changeExtension(outExtension);

    LibraryElement lib = await buildStep.inputLibrary;

    StyleGenerator state = StyleGenerator();

    // TODO(Alex): rename generated style class?
    // TODO(Alex): add Header and ignore lints
    // TODO(Alex): add linting for this project

    String partClass = state.generateForAnnotation(inputId, lib, styleAnnoConverter, styleKeyAnnoConverter);

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}
