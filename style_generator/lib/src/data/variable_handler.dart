part of "variable.dart";

/// merges the annotations of constructor parameters and class fields together.
///
/// Annotations on [constructorParams] are weighted over [fields] annotations.
///
/// We may speak of merging, but annotations are in fact replaced and not merged.
class VariableHandler {
  final ClassElement clazz;
  final ConstructorElement constructor;

  final Map<String, String> _lookupParamToField = {};

  late final List<Variable> constructorParams;
  late final List<Variable> fields;

  late final List<Variable> _merged = List.of(
    constructorParams.map((e) {
      return Variable(
        element: e.element,
        fieldElement: _lookupField(e),
      );
    }),
  );

  List<Variable> get merged => UnmodifiableListView(_merged);

  VariableHandler({required this.clazz, required this.constructor}) {
    constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    fields = clazz.getPropertyFields().map((e) => Variable(element: e)).toList();
  }

  FieldElement _lookupField(Variable parameter) {
    FieldElement? element = parameter.fieldElement;
    // the field element is inherently known by the constructor parameter, see [Variable._getFieldElement]
    if (element != null) return element;

    String? fieldName = _lookupParamToField[parameter.displayName];
    if (fieldName != null) {
      element = fields.firstWhereOrNull((variable) => variable.displayName == fieldName)?.element as FieldElement?;
    }

    // the field element is found through the lookup map
    if (element != null) return element;

    element = fields.firstWhereOrNull((variable) => variable == parameter)?.element as FieldElement?;

    // as our last resort, we map constructor parameters with fields if they are considered 'equal'
    // in practise, this can only happen if the lookup map is not exhaustive which means the function must add missing cases
    if (element == null)  throw Exception("Could not find field definition for '$parameter' in $fields");
    return element;
  }

  void mapParameterToFields(ResolvedLibraryResult resolvedLib) {
    ConstructorDeclaration? d = resolvedLib.resolve<ConstructorDeclaration>(constructor.firstFragment);
    if (d == null) throw Exception("ConstructorDeclaration not found for '$constructor'");

    _lookupParamToField.clear();

    _lookupParamToField.addAll(d.mapParameterToField());
  }

  void build<T>(AnnotationConverter<T> converter) {
    AnnotatedElement<T>? anno;
    for (var v in merged) {
      anno = _findAnnotation<T>(v, converter);

      if (anno != null) {
        bool hasMatchingType = v.element.isOfSameTypeAsTypeArgumentFromObject(anno.object, lessStrict: true, allowDynamic: true);
        if (!hasMatchingType) styleKeyTypeMismatch(v, anno.object.type);

        v._cache._inject(anno);
      }
    }
  }

  void resolveTypes(ResolvedLibraryResult resolvedLib) {
    for (var v in merged) {
      v.resolveType(resolvedLib);
    }
  }

  AnnotatedElement<T>? _findAnnotation<T>(Variable parameter, AnnotationConverter<T> converter) {
    for (var field in fields) {
      if (parameter == field) {
        return _getAnnotation<T>(parameter, field, converter);
      }
    }
    return null;
  }
}

AnnotatedElement<T>? _getAnnotation<T>(Variable parameter, Variable field, AnnotationConverter<T> converter) {
  AnnotatedElement<T>? anno = parameter._cache._getAnnotatedElement<T>(parameter.element, converter);
  AnnotatedElement<T>? fieldAnno = field._cache._getAnnotatedElement<T>(field.element, converter);

  return anno ?? fieldAnno;
}
