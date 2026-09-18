import "dart:async";
import "dart:io";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/session.dart";
import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:dart_style/dart_style.dart";
import "package:path/path.dart" hide Style;

import "../../annotations/style_config.dart";
import "../../annotations/to_string_config.dart";
import "../../builder_mixins/header_gen.dart";
import "../../data/logger.dart";
import "../../data/lookup_store.dart";
import "../../extensions/resolved_library_result_extension.dart";
import "to_string_generator.dart";

String get newLine => Platform.lineTerminator;

class ToStringBuilder with HeaderGen implements Builder {
  static const String outExtension = ".to_string.dart";

  static final LookupStore _lookupStore = LookupStore();

  final BuilderOptions options;

  ToStringBuilder({required this.options});

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
    ToStringConfig toStringConfig = ToStringConfig.fromConfig(config);

    LibraryElement lib = await buildStep.inputLibrary;
    AnalysisSession session = lib.session;
    ResolvedLibraryResult resolvedLib = await session.getResolvedLibraryByElement(lib) as ResolvedLibraryResult;

    ToStringGenerator state = ToStringGenerator(
      resolver: buildStep.resolver,
      resolvedLib: resolvedLib,
      store: _lookupStore,
      config: toStringConfig,
    );

    String partClass;
    ToStringGeneratorResult result = await state.generate();
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
