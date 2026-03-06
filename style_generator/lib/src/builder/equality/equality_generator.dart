import "dart:async";

import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/equality_generator_annotation.dart";

import "../../annotations/equality_config.dart";
import "../../annotations/equality_key_internal.dart";
import "../../builder_mixins/equals_gen.dart";
import "../../builder_mixins/fields_gen.dart";
import "../../builder_mixins/hash_gen.dart";
import "../../data/annotated_element.dart";
import "../../data/annotation_converter/annotation_converter.dart";
import "../../data/resolved_import.dart";
import "../../data/variable.dart";
import "../../extensions/element/type_parameter_element_list_extension_.dart";
import "../../extensions/element/type_parameterized_element_extension.dart";
import "../generator.dart";

class EqualityGeneratorResult extends GeneratorResult {
  final bool addPartDirective;
  final Iterable<ResolvedImport> imports;

  const EqualityGeneratorResult({required this.addPartDirective, required this.imports, required super.parts});
}

class GenResult extends PartGenResult {
  final bool addPartDirective;
  final Iterable<ResolvedImport> imports;

  const GenResult({required this.addPartDirective, required this.imports, required super.part});
}

final class EqualityGenerator extends Generator<Equality, EqualityKeyInternal, EqualityConfig>
    with FieldsGen, HashGen, EqualsGen {
  @override
  AnnotationConverter<Equality> get annotation => store.equalityAnnoConverter;

  @override
  AnnotationConverter<EqualityKeyInternal> get keyAnnotation => store.equalityKeyAnnoConverter;

  EqualityGenerator({
    required super.resolver,
    required super.resolvedLib,
    required super.store,
    required super.config,
  });

  @override
  Future<EqualityGeneratorResult> generate() async {
    return (await super.generate()) as EqualityGeneratorResult;
  }

  @override
  EqualityGeneratorResult mergeParts(List<PartGenResult> parts) {
    List<GenResult> results = List.from(parts, growable: false);

    return EqualityGeneratorResult(
      imports: results.fold<Set<ResolvedImport>>({}, (p, item) => p..addAll(item.imports)),
      addPartDirective: results.fold(false, (p, result) => p || result.addPartDirective),
      parts: results.map((e) => e.part).toList(growable: false),
    );
  }

  @override
  Future<GenResult> generateForClass(AnnotatedElement<Equality> annotatedClazz, EqualityConfig config) async {
    AnalyzedClass c = await analyzeClass(annotatedClazz, config.constructor, annotationTypeCheck: false);
    ClassElement clazz = c.clazz;

    List<Variable> fields = c.variables;

    String suffix = config.suffix;

    String generatedClassName = clazz.displayName + suffix;
    String fieldContent = generateFieldGetter(fields);
    HashGenResult hashResult = generateHash(
      fields,
      (v) => v.getAnnotationOf(keyAnnotation)?.inHash,
    );
    EqualsGenResult equalsResult = generateEquals(
      clazz.displayName,
      fields,
          (v) => v.getAnnotationOf(keyAnnotation)?.inEquals,
    );

    return GenResult(
      addPartDirective: true,
      imports: const [],
      part: _generatePartClass(
        generatedClassName,
        clazz.getTypedName(),
        clazz.typeParameters.typesToString(),
        fields: fieldContent,
        hash: hashResult.content,
        equals: equalsResult.content,
      ),
    );
  }


  String _generatePartClass(
    String generatedClassName,
    String className,
    String types, {
    required String fields,
    required String hash,
    required String equals,
  }) {
    String partClass;

    partClass = """
       
     mixin _\$$generatedClassName$types {
      
        $fields
        
        $hash
        
        $equals
     }

    """;

    return partClass;
  }
}
