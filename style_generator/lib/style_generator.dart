import "package:build/build.dart";

import "src/builder/copy_with/copy_with_builder.dart";
import "src/builder/style/style_builder.dart";

export "src/builder/copy_with/copy_with_builder.dart";
export "src/builder/style/style_builder.dart";

Builder styleBuilder(BuilderOptions options) => StyleBuilder(options: options);

Builder copyWithBuilder(BuilderOptions options) => CopyWithBuilder(options: options);
