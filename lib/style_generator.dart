import "package:build/build.dart";

import "src/style_builder/style_builder.dart";

export "src/annotations/style.dart";
export "src/annotations/style_key.dart";
export "src/style_builder/style_builder.dart";

Builder styleBuilder(BuilderOptions options) => StyleBuilder();
