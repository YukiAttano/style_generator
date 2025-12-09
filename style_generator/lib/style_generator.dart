import "package:build/build.dart";

import "src/style_builder/copy_with_builder.dart";
import "src/style_builder/style_builder.dart";

export "src/style_builder/copy_with_builder.dart";
export "src/style_builder/style_builder.dart";

Builder styleBuilder(BuilderOptions options) => StyleBuilder(options: options);

Builder copyWithBuilder(BuilderOptions options) => CopyWithBuilder(options: options);
