import "dart:async";
import "dart:io";

import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:dart_style/dart_style.dart";
import "package:path/path.dart" hide Style;
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../annotations/style_config.dart";
import "../annotations/style_key_internal.dart";
import "../builder_mixins/header_gen.dart";
import "../data/annotation_converter.dart";
import "../data/json_annotation_converter.dart";
import "style_part_generator.dart";

/*
    // Lookup classes from packages
    var asset = AssetId.resolve(Uri.parse("package:flutter/material.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);
    print(lib.exportNamespace.get2("ThemeExtension"));

 */

String get newLine => Platform.lineTerminator;

class StyleBuilder with HeaderGen implements Builder {
  static const String outExtension = ".style.dart";
  static const String annotationPackage = "package:style_generator_annotation/style_generator_annotation.dart";

  final BuilderOptions options;

  StyleBuilder({required this.options});

  @override
  final buildExtensions = const {
    ".dart": [outExtension],
  };

  bool _isInitialized = false;

  final Map<String, AnnotationConverter> _libraryAnnotations = {};

  AnnotationConverter<Style> get styleAnnoConverter => _libraryAnnotations["Style"]! as AnnotationConverter<Style>;

  AnnotationConverter<StyleKeyInternal> get styleKeyAnnoConverter =>
      _libraryAnnotations["StyleKey"]! as AnnotationConverter<StyleKeyInternal>;

  Future<void> _init(BuildStep buildStep) async {
    // create ClassElements of our annotations
    AssetId asset = AssetId.resolve(Uri.parse(annotationPackage));
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

    print("INPUT $inputId");


    Map<String, Object?> config = options.config;
    StyleConfig styleConfig = StyleConfig.fromConfig(config);

    LibraryElement lib = await buildStep.inputLibrary;

    StyleGenerator state = StyleGenerator(
      lib: lib,
      styleConfig: styleConfig,
      styleAnnotation: styleAnnoConverter,
      styleKeyAnnotation: styleKeyAnnoConverter,
    );

    String partClass;
    StyleGeneratorResult result = state.generate();
    String filename = basename(inputId.path);
    String header = generateHeader();

    if (result.isEmpty) {
      return;
    }

    partClass = """
    $header
    
    part of "$filename";
    
    ${result.parts.join("$newLine$newLine")}
    """;

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}
