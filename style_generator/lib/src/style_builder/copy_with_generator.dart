import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/copy_with_generator_annotation.dart";

import "../../style_generator.dart";
import "../annotations/copy_with_config.dart";
import "../annotations/copy_with_key_internal.dart";
import "../builder_mixins/copy_with_gen.dart";
import "../builder_mixins/fields_gen.dart";
import "../data/annotated_element.dart";
import "../data/annotation_converter/annotation_converter.dart";
import "../data/variable.dart";
import "../extensions/class_element_extension.dart";
import "../extensions/element_annotation_extension.dart";
import "../extensions/string_constructor_extension.dart";
import "generator.dart";

class CopyWithGeneratorResult extends GeneratorResult {
  final bool addPartDirective;

  const CopyWithGeneratorResult({required this.addPartDirective, required super.parts});
}

class _GenResult extends PartGenResult {
  final bool addPartDirective;

  const _GenResult({required this.addPartDirective, required super.part});
}

final class CopyWithGenerator extends Generator<CopyWith, CopyWithKeyInternal, CopyWithConfig> with FieldsGen, CopyWithGen {
  static String get _nl => newLine;

  @override
  AnnotationConverter<CopyWith> get annotation => store.copyWithAnnoConverter;

  @override
  AnnotationConverter<CopyWithKeyInternal> get keyAnnotation => store.copyWithKeyAnnoConverter;

  CopyWithGenerator({
    required super.resolvedLib,
    required super.store,
    required super.config,
  });

  @override
  CopyWithGeneratorResult generate() {
    return super.generate() as CopyWithGeneratorResult;
  }

  @override
  _GenResult generateForClass(AnnotatedElement<CopyWith> annotatedClazz, CopyWithConfig config) {
    AnalyzedClass c = analyzeClass(annotatedClazz, config.constructor?.asConstructorName);
    ClassElement clazz = c.clazz;

    List<Variable> variables = c.variables;

    String constructorName = (config.constructor ?? c.constructor.name!).asConstructorName;
    bool asExtension = config.asExtension ?? true;
    bool genFields = !asExtension;
    String suffix = config.suffix;

    String generatedClassName = clazz.displayName + suffix;
    String fieldContent = !genFields ? "" : generateFieldGetter(variables);
    String copyWithContent = generateCopyWith(
      clazz.displayName,
      constructorName,
      variables,
      (v) => v.getAnnotationOf(keyAnnotation)?.inCopyWith,
    );

    return _GenResult(
      addPartDirective: !asExtension,
      part: _generatePartClass(
        generatedClassName,
        clazz.displayName,
        fields: fieldContent,
        copyWith: copyWithContent,
        copyWithAsExtension: asExtension,
      ),
    );
  }

  @override
  CopyWithGeneratorResult mergeParts(List<PartGenResult> parts) {
    List<_GenResult> results = List.from(parts, growable: false);

    return CopyWithGeneratorResult(
      addPartDirective: results.fold(false, (p, result) => p || result.addPartDirective),
      parts: parts.map((e) => e.part).toList(growable: false),
    );
  }

  String _generateMixin(String generatedClassName, {required String fields, required String copyWith}) {
    return """
      mixin _\$$generatedClassName {
      
        $fields
        
        $copyWith
      }
    """;
  }

  String _generateExtension(String generatedClassName, String className, {required String copyWith}) {
    return """
      extension \$${generatedClassName}Extension on $className {
        $copyWith
      }
    """;
  }

  String _generatePartClass(
    String generatedClassName,
    String className, {
    required String fields,
    required String copyWith,
    required bool copyWithAsExtension,
    List<String> trailing = const [],
  }) {
    String partClass;
    String mixin;
    String extension;
    bool hasMixin = !copyWithAsExtension || trailing.isNotEmpty;

    mixin = _generateMixin(generatedClassName, fields: fields, copyWith: copyWith);
    extension = _generateExtension(generatedClassName, className, copyWith: copyWith);

    partClass = """
       
    ${hasMixin ? mixin : ""}

    ${copyWithAsExtension ? extension : ""}

    """;

    return partClass;
  }

}
