import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/session.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:style_generator_annotation/copy_with_generator_annotation.dart";
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../annotations/copy_with_config.dart";
import "../annotations/copy_with_key_internal.dart";
import "../annotations/style_config.dart";
import "../annotations/style_key_internal.dart";
import "annotation_converter/annotation_converter.dart";
import "annotation_converter/json_annotation_converter.dart";

class LookupStore {
  static const String styleAnnotationPackage = "package:style_generator_annotation/style_generator_annotation.dart";
  static const String copyWithAnnotationPackage = "package:style_generator_annotation/copy_with_generator_annotation.dart";
  static const String materialPackage = "package:flutter/material.dart";

  static const String styleKeyName = StyleKeyInternal.srcAnnotationName;
  static const String styleName = StyleConfig.srcAnnotationName;
  static const String copyWithName = CopyWithConfig.srcAnnotationName;
  static const String copyWithKeyName = CopyWithKeyInternal.srcAnnotationName;
  static const String buildContextName = "BuildContext";

  final Map<String, AnnotationConverter> _libraryAnnotations = {};

  final Map<String, DartType> _dartTypes = {};

  bool _isInitialized = false;

  AnnotationConverter<Style> get styleAnnoConverter => _libraryAnnotations[styleName]! as AnnotationConverter<Style>;

  AnnotationConverter<StyleKeyInternal> get styleKeyAnnoConverter => _libraryAnnotations[styleKeyName]! as AnnotationConverter<StyleKeyInternal>;

  AnnotationConverter<CopyWith> get copyWithAnnoConverter => _libraryAnnotations[copyWithName]! as AnnotationConverter<CopyWith>;

  AnnotationConverter<CopyWithKeyInternal> get copyWithKeyAnnoConverter => _libraryAnnotations[copyWithKeyName]! as AnnotationConverter<CopyWithKeyInternal>;


  DartType get buildContextType => _dartTypes[buildContextName]!;

  late ResolvedLibraryResult _resolvedLibrary;
  ResolvedLibraryResult get resolvedLibrary {
    assert(_isInitialized, "You must initialized this object first with init()");
    return _resolvedLibrary;
  }

  LookupStore();

  Future<void> init(BuildStep buildStep) async {
    await _initResolvedLibrary(buildStep);

    if (_isInitialized) return Future.value();

    await _initStyle(buildStep);
    await _initMaterial(buildStep);

    _isInitialized = true;
  }

  /// Resolves the current library and all its references to existing elements
  ///
  /// This result should not be cached to avoid stale references
  Future<void> _initResolvedLibrary(BuildStep buildStep) async {
    LibraryElement lib = await buildStep.inputLibrary;

    AnalysisSession session = lib.session;
    _resolvedLibrary = await session.getResolvedLibraryByElement(lib) as ResolvedLibraryResult;
  }

  Future<void> _initStyle(BuildStep buildStep) async {
    AssetId styleAsset = AssetId.resolve(Uri.parse(styleAnnotationPackage));
    AssetId copyWithAsset = AssetId.resolve(Uri.parse(copyWithAnnotationPackage));
    LibraryElement styleLib = await buildStep.resolver.libraryFor(styleAsset);
    LibraryElement copyWithLib = await buildStep.resolver.libraryFor(copyWithAsset);

    // create ClassElements of our annotations and
    // create converter for the ClassElements to read the configured Annotations from real DartObjects

    _createAnnotationFromJson<Style>(styleLib, styleName, Style.fromJson);
    _createAnnotationFromMap<StyleKeyInternal>(styleLib, styleKeyName,  (map) => createStyleKey(resolvedLibrary, map));
    _createAnnotationFromJson<CopyWith>(copyWithLib, copyWithName, CopyWith.fromJson);
    _createAnnotationFromJson<CopyWithKeyInternal>(copyWithLib, copyWithKeyName, CopyWithKeyInternal.fromJson);
  }

  void _createAnnotationFromJson<T>(LibraryElement library, String annoName, AnnotationFromJson<T> fromJson) {
    ClassElement? annoElement = library.exportNamespace.get2(annoName) as ClassElement?;

    if (annoElement != null) {
      _libraryAnnotations[annoName] = JsonAnnotationConverter<T>(
        annotationClass: annoElement,
        buildAnnotation: fromJson,
      );
    }
  }

  void _createAnnotationFromMap<T>(LibraryElement library, String annoName, AnnotationFromMap<T> fromMap) {
    ClassElement? annoElement = library.exportNamespace.get2(annoName) as ClassElement?;

    if (annoElement != null) {
      _libraryAnnotations[annoName] = AnnotationConverter<T>(
        annotationClass: annoElement,
        buildAnnotation: fromMap,
      );
    }
  }

  Future<void> _initMaterial(BuildStep buildStep) async {
    AssetId materialAsset = AssetId.resolve(Uri.parse(materialPackage));
    LibraryElement materialLib = await buildStep.resolver.libraryFor(materialAsset);
    ClassElement? buildContextElement = materialLib.exportNamespace.get2(buildContextName) as ClassElement?;

    if (buildContextElement != null) {
      _dartTypes[buildContextName] = buildContextElement.thisType.extensionTypeErasure;
    }
  }
}
