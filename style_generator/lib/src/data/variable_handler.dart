part of "variable.dart";

/// merges the annotations of constructor parameters and class fields together.
///
/// Annotations on [constructorParams] are weighted over [fields] annotations.
///
/// We may speak of merging, but annotations are in fact replaced and not merged.
class VariableHandler {
  final ClassElement clazz;
  final ConstructorElement constructor;

  /// map constructor elements and their declaration for [_lookupField]
  final Map<ConstructorElement, ConstructorDeclaration> _constructors = {};

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
    // short circuit lookup if the field is already assigned
    if (parameter.fieldElement != null) return parameter.fieldElement!;

    return _lookupTree(parameter.element);
  }

  FieldElement _lookupTree(VariableElement element) {
    FieldElement? field;

    switch (element) {
      case FieldElement():
        field = element;
      case FieldFormalParameterElement():
        field = element.field;
      case SuperFormalParameterElement():
        field = _lookupTree(element.superConstructorParameter!);
      case FormalParameterElement():
        var constructorElement = element.enclosingElement;
        ConstructorDeclaration? d = _constructors[constructorElement];

        if (d != null) {
          var map = d.mapParameterToField(lookup: (superParameter) => _lookupTree(superParameter).displayName);

          String fieldName = map[element.displayName]!;
          field = fields.firstWhereOrNull((f) => f.displayName == fieldName)?.fieldElement;
        }
    }

    return field!;
  }

  FutureOr<void> indexConstructorDeclarations(Resolver resolver, ResolvedLibraryResult resolvedLib) async {
    ConstructorDeclaration? d = resolvedLib.resolve<ConstructorDeclaration>(constructor.firstFragment);
    if (d == null) throw Exception("ConstructorDeclaration not found for '$constructor'");

    _constructors.clear();
    _constructors[constructor] = d;

    ConstructorElement? superConstructor = constructor.superConstructor;

    while (superConstructor != null && (!superConstructor.library.isDartCore && !superConstructor.library.isDartAsync)) {
      ConstructorDeclaration? superDeclaration = await resolver.astNodeFor(superConstructor.firstFragment, resolve: true) as ConstructorDeclaration?;

      if (superDeclaration != null) {
        _constructors[superConstructor] = superDeclaration;
      }

      superConstructor = superConstructor.superConstructor;
    }
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
