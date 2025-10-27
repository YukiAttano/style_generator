import "dart:async";
import "dart:io";

import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:dart_style/dart_style.dart";
import "package:path/path.dart" hide Style;

import "../annotations/style_config.dart";
import "../builder_mixins/header_gen.dart";
import "../data/lookup_store.dart";
import "style_part_generator.dart";

/*
    // Lookup classes from packages
    var asset = AssetId.resolve(Uri.parse("package:flutter/material.dart"));
    var lib = await buildStep.resolver.libraryFor(asset);
    print(lib.exportNamespace.get2("ThemeExtension"));

 */

// TODO(Yuki): check StyleKeys type against fields/parameters type (and whether a subclass is allowed)
// TODO(Yuki): generate part file either at the location defined by "part .style.part" directive or merge with ".g.dart"

String get newLine => Platform.lineTerminator;

class StyleBuilder with HeaderGen implements Builder {
  static const String outExtension = ".style.dart";

  static final LookupStore _lookupStore = LookupStore();

  final BuilderOptions options;

  StyleBuilder({required this.options});

  @override
  final buildExtensions = const {
    ".dart": [outExtension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    await _lookupStore.init(buildStep);

    DartFormatter formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

    AssetId inputId = buildStep.inputId;
    AssetId outputId = inputId.changeExtension(outExtension);

    Map<String, Object?> config = options.config;
    StyleConfig styleConfig = StyleConfig.fromConfig(config);

    LibraryElement lib = await buildStep.inputLibrary;

    StyleGenerator state = StyleGenerator(
      lib: lib,
      styleConfig: styleConfig,
      store: _lookupStore,
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
