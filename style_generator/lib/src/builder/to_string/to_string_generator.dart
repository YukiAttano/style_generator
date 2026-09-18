import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/to_string_generator_annotation.dart";

import "../../annotations/to_string_config.dart";
import "../../annotations/to_string_key_internal.dart";
import "../../builder_mixins/fields_gen.dart";
import "../../builder_mixins/to_string_gen.dart";
import "../../data/annotated_element.dart";
import "../../data/annotation_converter/annotation_converter.dart";
import "../../data/variable.dart";
import "../../extensions/element/type_parameterized_element_extension.dart";
import "../generator.dart";

class ToStringGeneratorResult extends GeneratorResult {
  const ToStringGeneratorResult({required super.parts});
}

final class ToStringGenerator extends Generator<ToString, ToStringKeyInternal, ToStringConfig>
    with FieldsGen, ToStringGen {
  @override
  AnnotationConverter<ToString> get annotation => store.toStringAnnoConverter;

  @override
  AnnotationConverter<ToStringKeyInternal> get keyAnnotation => store.toStringKeyAnnoConverter;

  ToStringGenerator({
    required super.resolver,
    required super.resolvedLib,
    required super.store,
    required super.config,
  });

  @override
  Future<ToStringGeneratorResult> generate() async {
    return (await super.generate()) as ToStringGeneratorResult;
  }

  @override
  ToStringGeneratorResult mergeParts(List<PartGenResult> parts) {
    return ToStringGeneratorResult(parts: parts.map((e) => e.part).toList(growable: false));
  }

  @override
  Future<PartGenResult> generateForClass(AnnotatedElement<ToString> annotatedClazz, ToStringConfig config) async {
    AnalyzedClass c = await analyzeClass(annotatedClazz, null);
    ClassElement clazz = c.clazz;

    List<Variable> fields = c.variables;

    String suffix = config.suffix;

    String fieldContent = generateFieldGetter(fields);
    ToStringGenResult toStringContent = generateToString(
      fields,
      clazz.displayName,
      keyAnnotation,
    );

    return PartGenResult(
      part: _generatePartClass(
        clazz.getTypedName(suffix: suffix),
        fields: fieldContent,
        toString: toStringContent.content,
      ),
    );
  }

  String _generatePartClass(
    String generatedClassName, {
    required String fields,
    required String toString,
  }) {
    String partClass =
        """
       
    mixin _\$$generatedClassName {

      $fields
      
      $toString
      
    }

    """;

    return partClass;
  }
}
