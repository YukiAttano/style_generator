import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';

import 'package:style_generator/src/data/annotated_element.dart';
import 'package:style_generator/src/data/annotation_converter.dart';
import 'package:style_generator/src/data/variable.dart';
import '../annotations/style_key_internal.dart';
import 'package:style_generator/src/extensions/dart_type_extension.dart';
import 'package:style_generator/src/extensions/element_annotation_extension.dart';
import 'package:style_generator/style_generator.dart';

mixin OfGen {


  String generateOf(String className, String fallbackConstructor) {
    String function =
        """
        $className _\$of(BuildContext context, [$className? style]) {
          $className s = $className.$fallbackConstructor(context);
          s = s.merge(Theme.of(context).extension<SomeStyle>());
          s = s.merge(style);
    
          return s;
        }
        """;

    return function;
  }
}
