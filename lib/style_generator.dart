import 'package:build/build.dart';
import 'src/copy_builder.dart';
import 'src/style_builder/style_builder.dart';

export 'src/copy_builder.dart';
export 'src/style_builder/style_builder.dart';
export 'src/annotations/style.dart';
export 'src/annotations/style_key.dart';

Builder copyBuilder(BuilderOptions options) => CopyBuilder();
Builder styleBuilder(BuilderOptions options) => StyleBuilder();