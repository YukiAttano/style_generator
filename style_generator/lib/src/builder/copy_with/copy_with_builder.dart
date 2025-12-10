import "dart:async";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/session.dart";
import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";
import "package:dart_style/dart_style.dart";
import "package:path/path.dart";

import "../../../style_generator.dart";
import "../../annotations/copy_with_config.dart";
import "../../builder_mixins/header_gen.dart";
import "../../data/lookup_store.dart";
import "../../data/resolved_import.dart";
import "copy_with_generator.dart";

class CopyWithBuilder with HeaderGen implements Builder {
  static const String outExtension = ".copy_with.dart";

  static final LookupStore _lookupStore = LookupStore();

  final BuilderOptions options;

  CopyWithBuilder({required this.options});

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
    CopyWithConfig copyWithConfig = CopyWithConfig.fromConfig(config);

    LibraryElement lib = await buildStep.inputLibrary;
    AnalysisSession session = lib.session;
    ResolvedLibraryResult resolvedLib = await session.getResolvedLibraryByElement(lib) as ResolvedLibraryResult;

    CopyWithGenerator state = CopyWithGenerator(
      resolvedLib: resolvedLib,
      store: _lookupStore,
      config: copyWithConfig,
    );

    String partClass;
    CopyWithGeneratorResult result = state.generate();
    String filename = basename(inputId.path);
    String header = generateHeader();
    Set<ResolvedImport> imports = result.imports.toSet();
    imports.add(ResolvedImport(uri: lib.uri));

    if (result.isEmpty) {
      return;
    }

    partClass = """
    $header
    
    ${() {
      if (result.addPartDirective) {
        return 'part of "$filename";';
      } else {
        return imports.map((e) => "import $e;",).join(newLine);
      }
    }()}

    ${result.parts.join("$newLine$newLine")}

    """;

    partClass = formatter.format(partClass);

    await buildStep.writeAsString(outputId, partClass);
  }
}
