import "dart:async";
import "dart:io";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/session.dart";
import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:dart_style/dart_style.dart";
import "package:path/path.dart" hide Style;

import "../../annotations/style_config.dart";
import "../../builder_mixins/header_gen.dart";
import "../../data/logger.dart";
import "../../data/lookup_store.dart";
import "../../extensions/resolved_library_result_extension.dart";
import "style_generator.dart";

// TODO(Yuki): add invertedMerge
// TODO(Yuki): maybe design merge method to work inverted to current implementation because some (maybe all?) flutter internal merge functions work like that
// TODO(Yuki): maybe check whether StyleKeys type is a subclass of the fields/parameters type
// TODO(Yuki): generate part file at the location defined by "part .style.part" directive

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
    AnalysisSession session = lib.session;
    ResolvedLibraryResult resolvedLib = await session.getResolvedLibraryByElement(lib) as ResolvedLibraryResult;

    StyleGenerator state = StyleGenerator(
      resolver: buildStep.resolver,
      resolvedLib: resolvedLib,
      store: _lookupStore,
      config: styleConfig,
    );

    String partClass;
    StyleGeneratorResult result = await state.generate();
    String filename = basename(inputId.path);
    String header = generateHeader();

    if (result.isEmpty) {
      return;
    }

    bool hasPartDirective = resolvedLib.containsPart(inputId, outputId);

    if (!hasPartDirective) missingPartDeclaration(basename(outputId.path));

    partClass = """
    $header
    
    part of "$filename";
    
    ${result.parts.join("$newLine$newLine")}
    """;

    partClass = formatter.format(partClass, uri: outputId.uri);

    await buildStep.writeAsString(outputId, partClass);
  }
}
