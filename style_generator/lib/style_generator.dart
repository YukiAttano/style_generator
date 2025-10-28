import "package:build/build.dart";

import "src/style_builder/style_builder.dart";

export "dart:ui" show lerpDouble;

export "src/style_builder/style_builder.dart";

Builder styleBuilder(BuilderOptions options) => StyleBuilder(options: options);
