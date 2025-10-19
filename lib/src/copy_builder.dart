import 'package:build/build.dart';

class CopyBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.dart.copy']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Create the output ID from the build step input ID.
    AssetId inputId = buildStep.inputId;
    AssetId outputId = inputId.addExtension('.copy');

    // Read from the input, write to the output.
    String contents = await buildStep.readAsString(inputId);
    await buildStep.writeAsString(outputId, contents);
  }
}