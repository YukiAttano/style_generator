import "package:analyzer/dart/element/element.dart";
import "package:style_generator_annotation/style_generator_annotation.dart";

import "../../../style_generator.dart";
import "../../annotations/style_config.dart";
import "../../annotations/style_key_internal.dart";
import "../../builder_mixins/copy_with_gen.dart";
import "../../builder_mixins/fields_gen.dart";
import "../../builder_mixins/lerp_gen.dart";
import "../../builder_mixins/merge_gen.dart";
import "../../builder_mixins/of_gen.dart";
import "../../data/annotated_element.dart";
import "../../data/annotation_converter/annotation_converter.dart";
import "../../data/variable.dart";
import "../../extensions/element/class_element_extension.dart";
import "../../extensions/string_constructor_extension.dart";
import "../../extensions/element/type_parameter_element_list_extension_.dart";
import "../../extensions/element/type_parameterized_element_extension.dart";
import "../generator.dart";

class StyleGeneratorResult extends GeneratorResult {
  const StyleGeneratorResult({required super.parts});
}

final class StyleGenerator extends Generator<Style, StyleKeyInternal, StyleConfig>
    with FieldsGen, LerpGen, MergeGen, CopyWithGen, OfGen {
  static String get _nl => newLine;

  AnnotationConverter<Style> get annotation => store.styleAnnoConverter;

  AnnotationConverter<StyleKeyInternal> get keyAnnotation => store.styleKeyAnnoConverter;

  StyleGenerator({
    required super.resolvedLib,
    required super.store,
    required super.config,
  });

  @override
  StyleGeneratorResult generate() {
    return super.generate() as StyleGeneratorResult;
  }

  @override
  StyleGeneratorResult mergeParts(List<PartGenResult> parts) {
    return StyleGeneratorResult(parts: parts.map((e) => e.part).toList(growable: false));
  }

  @override
  PartGenResult generateForClass(AnnotatedElement<Style> annotatedClazz, StyleConfig config) {
    AnalyzedClass c = analyzeClass(annotatedClazz, config.constructor?.asConstructorName);
    ClassElement clazz = c.clazz;

    List<Variable> variables = c.variables;

    ConstructorElement? fallbackConstructor = _getConstructor(clazz.constructors, config.fallback);
    ConstructorElement? ofConstructor = _getConstructor(clazz.constructors, "of");

    Variable? buildContext = _getBuildContextParameterFrom(fallback: fallbackConstructor, of: ofConstructor);

    String constructorName = (config.constructor ?? c.constructor.name!).asConstructorName;
    String fallback = (config.fallback ?? "").asConstructorName;
    bool genFields = config.genFields;
    bool genCopyWith = config.genCopyWith;
    bool genMerge = config.genMerge;
    bool genLerp = config.genLerp;
    bool genOf = config.genOf ?? buildContext != null;
    String suffix = config.suffix;

    String generatedClassName = clazz.getTypedName(suffix: suffix);
    String fieldContent = !genFields ? "" : generateFieldGetter(variables);
    String ofContent = !genOf ? "" : generateOf(clazz.displayName, suffix, buildContext, fallback);
    CopyWithGenResult copyWithContent = !genCopyWith
        ? const CopyWithGenResult()
        : generateCopyWith(
            clazz.displayName,
            clazz.typeParameters.typesToString(),
            constructorName,
            variables,
            (v) => v.getAnnotationOf(keyAnnotation)?.inCopyWith,
          );
    String mergeContent = !genMerge ? "" : generateMerge(resolvedLib, clazz.displayName, variables, keyAnnotation);
    LerpGenResult lerpContent = !genLerp
        ? const LerpGenResult()
        : generateLerp(resolvedLib, clazz.displayName, constructorName, variables, keyAnnotation);

    return PartGenResult(
      part: _generatePartClass(
        generatedClassName,
        fields: fieldContent,
        of: ofContent,
        copyWith: copyWithContent.content,
        merge: mergeContent,
        lerp: lerpContent.content,
        trailing: [...lerpContent.trailing],
      ),
    );
  }

  Variable? _getBuildContextParameterFrom({ConstructorElement? fallback, ConstructorElement? of}) {
    if (fallback == null || of == null) return null;

    List<FormalParameterElement> params = fallback.formalParameters;

    if (params.isNotEmpty) {
      // if our first parameter is positional, it must be of type BuildContext because we cannot pass other arguments
      // into our fallback constructor
      FormalParameterElement p = params.first;
      if (p.isPositional) {
        if (p.type == store.buildContextType) {
          return Variable(element: p);
        } else {
          return null;
        }
      }

      // if the first is not positional, none will be positional so we can search for our fitting parameter.
      // we do not check if other parameter are required, so we might still generate a broken of() constructor.
      // This is fine, because the dart analyzer will tell the user whats wrong
      for (var p in params) {
        if (p.type == store.buildContextType) {
          return Variable(element: p);
        }
      }
    }

    return null;
  }

  String _generatePartClass(
    String generatedClassName, {
    required String fields,
    required String of,
    required String copyWith,
    required String merge,
    required String lerp,
    List<String> trailing = const [],
  }) {
    String partClass = """
       
    mixin _\$$generatedClassName {

      $fields
      
      $copyWith
      
      $merge
      
      $lerp
      
      ${trailing.join("$_nl$_nl")}
    }

    $of 
    """;

    return partClass;
  }

  ConstructorElement? _getConstructor(List<ConstructorElement> constructors, String? name) {
    ConstructorElement? constructor;

    if (name == null) {
      constructor = constructors.getPrimaryConstructor();
    } else {
      //  // ignore:  parameter_assignments .
      //  if (name == "") name = "new"; // Default Constructor name

      for (var c in constructors) {
        if (c.name == name && c.name != null) {
          constructor = c;
          break;
        }
      }
    }

    return constructor;
  }
}
