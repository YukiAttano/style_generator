import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/session.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../annotations/style_key_internal.dart";
import "annotation_converter.dart";
import "json_annotation_converter.dart";
import "logger.dart";

class LookupStore {
  static const String annotationPackage = "package:style_generator_annotation/style_generator_annotation.dart";
  static const String materialPackage = "package:flutter/material.dart";

  final Map<String, AnnotationConverter> _libraryAnnotations = {};

  final Map<String, DartType> _dartTypes = {};

  bool _isInitialized = false;

  AnnotationConverter<Style> get styleAnnoConverter => _libraryAnnotations["Style"]! as AnnotationConverter<Style>;

  AnnotationConverter<StyleKeyInternal> get styleKeyAnnoConverter =>
      _libraryAnnotations["StyleKey"]! as AnnotationConverter<StyleKeyInternal>;

  DartType get buildContextType => _dartTypes["BuildContext"]!;

  LookupStore();

  Future<void> init(BuildStep buildStep) async {
    if (_isInitialized) return Future.value();

    await _initStyle(buildStep);
    await _initMaterial(buildStep);

    _isInitialized = true;
  }

  Future<void> _initStyle(BuildStep buildStep) async {
    AssetId styleAsset = AssetId.resolve(Uri.parse(annotationPackage));
    LibraryElement styleLib = await buildStep.resolver.libraryFor(styleAsset);

    LibraryElement lib = await buildStep.inputLibrary;

    AnalysisSession session = lib.session;
    ResolvedLibraryResult resolved = await session.getResolvedLibraryByElement(lib) as ResolvedLibraryResult ;


    CompilationUnit compilationUnit =
    await buildStep.resolver.compilationUnitFor(buildStep.inputId);
    //ResolvedLibraryResult r;

    // var v = TestVisitor();
    //  compilationUnit.declarations.forEach((element) {
    //    warn("AST ${element}");
    //    element.accept(v);
    //  },);

    // compilationUnit.directives.forEach((element) {
    //   warn("AST ${element}");
    //   element.accept(v);
    // },);


    /*
      for (final unit in resolvedLibrary.units) {

      unit.unit.accept(collector);

      if (collector.prefixName != null) {
        final prefix = collector.prefixName; // "c"
        // hier weiterverarbeiten …
        break;
      }
    }
    */




    // create ClassElements of our annotations
    ClassElement? styleElement = styleLib.exportNamespace.get2("Style") as ClassElement?;
    ClassElement? styleKeyElement = styleLib.exportNamespace.get2("StyleKey") as ClassElement?;

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
        buildAnnotation: (map) => createStyleKey(resolved, compilationUnit, map),
      );
    }
  }

  Future<void> _initMaterial(BuildStep buildStep) async {
    AssetId materialAsset = AssetId.resolve(Uri.parse(materialPackage));
    LibraryElement materialLib = await buildStep.resolver.libraryFor(materialAsset);
    ClassElement? buildContextElement = materialLib.exportNamespace.get2("BuildContext") as ClassElement?;

    if (buildContextElement != null) {
      _dartTypes["BuildContext"] = buildContextElement.thisType.extensionTypeErasure;
    }
  }
}
