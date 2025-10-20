import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import 'package:style_generator/src/extensions/dart_object_extension.dart';
import 'package:style_generator/src/style_builder/builder_state.dart';

import '../../style_generator.dart';
import '../data/json_annotation_builder.dart';

/*
    // Lookup classes from packages
    var asset = AssetId.resolve(Uri.parse("package:flutter/material.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);
    print(lib.exportNamespace.get2("ThemeExtension"));

 */

class SomeGen extends GeneratorForAnnotation {}

class StyleBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.style.dart'],
  };

  bool _isInitialized = false;

  final Map<String, AnnotationBuilder> _libraryAnnotations = {};

  AnnotationBuilder<Style> get styleAnnoBuilder => _libraryAnnotations["Style"] as AnnotationBuilder<Style>;

  AnnotationBuilder<StyleKey> get styleKeyAnnoBuilder => _libraryAnnotations["StyleKey"] as AnnotationBuilder<StyleKey>;

  Future<void> _init(BuildStep buildStep) async {
    var asset = AssetId.resolve(Uri.parse("package:style_generator/style_generator.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);

    ClassElement? styleElement = lib.exportNamespace.get2("Style") as ClassElement?;
    ClassElement? styleKeyElement = lib.exportNamespace.get2("StyleKey") as ClassElement?;
    if (styleElement != null) {
      _libraryAnnotations["Style"] = JsonAnnotationBuilder<Style>(
        annotationClass: styleElement,
        buildAnnotation: Style.fromJson,
      );
    }
    if (styleKeyElement != null) {
      _libraryAnnotations["StyleKey"] = AnnotationBuilder<StyleKey>(
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

    // Create the output ID from the build step input ID.
    AssetId inputId = buildStep.inputId;
    AssetId outputId = inputId.changeExtension('.style.dart');

    var l = await buildStep.inputLibrary;

    BuilderState state = BuilderState();

    String partClass = state.generateForAnnotation(inputId, l, styleAnnoBuilder, styleKeyAnnoBuilder);

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}

StyleKey<T> createStyleKey<T>(Map<String, DartObject?> map) {
  ExecutableElement? lerp = map["lerp"]?.toFunctionValue();

  String? callbackName;
  if (lerp != null && lerp.isStatic) {
    switch (lerp.kind) {
      case ElementKind.METHOD:
        callbackName = "${lerp.enclosingElement?.displayName ?? ""}${lerp.displayName}";
      case ElementKind.FUNCTION:
        callbackName = lerp.displayName;
    }
  }

  return StyleKey.internal(
      inLerp: map["inLerp"]?.toValue() as bool?,
      inMerge: map["inMerge"]?.toValue() as bool? ,
      inCopyWith: map["inCopyWith"]?.toValue() as bool?,
      functionCall: callbackName,
  );
}

