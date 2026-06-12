part of "variable.dart";

enum FieldType {
  FIELD,
  CONSTRUCTOR_PARAM,
  MERGED;
}

/// merges the annotations of constructor parameters and class fields together.
///
/// Annotations on [constructorParams] are weighted over [fields] annotations.
///
/// We may speak of merging, but annotations are in fact replaced and not merged.
class VariableHandler {
  final ClassElement clazz;
  final ConstructorElement constructor;

  /// Map constructor elements and their declaration for [_lookupField]
  /// This one holds concrete implementations like
  /// `GenParent<DataStuff, String>({required String some, required DataStuff? something})`
  final Map<ConstructorElement, ConstructorDeclaration> _constructors = {};
  /// This one holds generic implementations like
  /// `GenParent<T, L>({required String some, required DataStuff? something})`
  final Map<ConstructorElement, ConstructorDeclaration> _baseConstructors = {};

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

  /// returns the corresponding list of variables by [type] to allow dynamic access
  @protected
  List<Variable> getVariablesByType(FieldType type) => switch (type) {
        FieldType.FIELD => fields,
        FieldType.CONSTRUCTOR_PARAM => constructorParams,
        FieldType.MERGED => merged,
      };

  VariableHandler({required this.clazz, required this.constructor}) {
    constructorParams = constructor.formalParameters.map((e) => Variable(element: e)).toList();
    fields = clazz.getPropertyFields().map((e) => Variable(element: e)).toList();
  }

  FieldElement _lookupField(Variable parameter) {
    // short circuit lookup if the field is already assigned
    if (parameter.fieldElement != null) parameter.fieldElement!;

    return _lookupTree(parameter.element);
  }



  /// Will find the field of a constructor parameter.
  ///
  /// The following code shows a specific case were the type information of the constructor parameters are lost.
  /// By default, if the inheritance structure wouldn't contain generic definitions, all SuperFormal..
  /// would map very likely map to a FieldFormal.., but with the use of _multiple_ generic ancestors, they are all resolved
  /// to FormalParameter.. which have a more complex lookup.
  /// Example:
  /// ```dart
  /// class GenChild extends GenIntermediate<DataStuff, String> with _$GenChild {
  ///   final String local;
  ///
  ///   const GenChild({            //     (underscore for better readability)
  ///     required this.local,      // <-- Field_FormalParameterElement
  ///     required super.some,      // <-- Super_FormalParameterElement
  ///     required super.something, // <-- Super_FormalParameterElement
  ///     required super.bim        // <-- Super_FormalParameterElement
  ///   });
  /// }
  ///
  /// class GenIntermediate<T, L> extends GenParent<T, L> {
  ///   // all parameter here are SuperFormalParameterElements
  ///   const GenIntermediate({required super.some, required super.something, required super.bim});
  /// }
  ///
  /// class GenParent<T, L> {
  ///   final String some;
  ///   final T something;
  ///   final L? bimbo;
  ///   final String nothing;
  ///
  ///   const GenParent({
  ///     required this.some,       // <-- without generics, this would be a FieldFormal.. but with generics, it is a Formal..
  ///     required this.something,  // <-- without generics, this would be a FieldFormal.. but with generics, it is a Formal..
  ///     required L? bim           // <-- this one is the _second_! special case
  ///   }) :
  ///         bimbo = bim,
  ///         nothing = "";
  /// }
  /// ```
  /// Important info: The returned [FieldElement] may be resolved with [ResolvedType] to something which
  /// contains a [DartType] of [TypeParameterType].
  /// This [TypeParameterType] represents a generic (like T, L, ...) and is mostly not what we need, because the [ResolvedType]
  /// exists to actually resolve generics to a concrete class.
  /// However: It is technically correct that this method returns the [FieldElement] of that type.
  /// Therefor the [VariableHandler] will take care of the conversion.
  FieldElement _lookupTree(VariableElement element) {
    FieldElement? field;

    switch (element) {
      case FieldElement():
        field = element;
      case FieldFormalParameterElement():
        field = element.field;
      case SuperFormalParameterElement():
        // [element.superConstructorParameter] looses type information
        // (the returned type is always [FormalParameterElement], even for [FieldFormalParameterElement]s for example.
        var superElement = element.superConstructorParameter;

        field = _lookupTree(superElement!);
      case FormalParameterElement():
        var constructorElement = element.enclosingElement;
        ConstructorDeclaration? d = _constructors[constructorElement];

        FieldElement? checkInitializersOf(ConstructorDeclaration d) {
          var map = d.mapInitializersToField(lookup: (superParameter) => _lookupTree(superParameter).displayName);

          String? fieldName = map[element.displayName];
          return fields.firstWhereOrNull((f) => f.displayName == fieldName)?.fieldElement;
        }

        if (d != null) {
          // We enter this part, when we have to map a constructor parameter via the initializers (the : behind the constructor)
          // to the field.
          field = checkInitializersOf(d);

          assert(field != null, "We expected that parameter:'$element' must be mapped through initializers, but none were found");
        } else {
          // We enter here, when the Example from the doc above hits and we have to map the given constructor parameter
          // 'element' like 'required DataStuff? something' to the constructor parameter 'required T? something'
          d = _baseConstructors[constructorElement];

          if (d != null) {
            // Taken the example above, this one will find nothing for 'required DataStuff? something' and 'required String bim'.
            // read the comments down below, this one is matched for the 'required L? bim' lookup (the generic).
            field = checkInitializersOf(d);

            // This one resolves
            // - 'required DataStuff? something' to 'required this.something'
            // - 'required String bim'           to 'required L? bim'
            if (field == null) {
              for (var param in d.parameters.parameters) {
                if (param.declaredFragment == element.firstFragment) {
                  // it then resolves
                  // - 'requires this.something' to the field via the 'FieldFormalParameterElement'
                  // - 'requires L? bim' enters again the 'FormalParameterElement' but hits the `field = checkInitializersOf(d);` above
                  field = _lookupTree(param.declaredFragment!.element);
                  break;
                }
              }
            }
          }
        }
    }

    return field!;
  }

  FutureOr<void> indexConstructorDeclarations(Resolver resolver, ResolvedLibraryResult resolvedLib) async {
    ConstructorDeclaration? d = resolvedLib.resolve<ConstructorDeclaration>(constructor.firstFragment);
    if (d == null) throw Exception("ConstructorDeclaration not found for '$constructor'");

    _constructors.clear();
    _constructors[constructor] = d;
    _baseConstructors[constructor.baseElement] = d;

    ConstructorElement? superConstructor = constructor.superConstructor;

    // @formatter:off
    while (superConstructor != null && (!superConstructor.library.isDartCore && !superConstructor.library.isDartAsync)) {
      ConstructorDeclaration? superDeclaration = await resolver.astNodeFor(superConstructor.firstFragment, resolve: true) as ConstructorDeclaration?;

      if (superDeclaration != null) {
        _constructors[superConstructor] = superDeclaration;
        _baseConstructors[superConstructor.baseElement] = superDeclaration;
      }

      superConstructor = superConstructor.superConstructor;
    }
  }
  // @formatter:on

  /// builds the annotation cache for [merged]
  void build<T>(AnnotationConverter<T> converter, {FieldType? type, bool? annotationTypeCheck}) {
    type ??= FieldType.MERGED;
    annotationTypeCheck ??= true;

    AnnotatedElement<T>? anno;
    List<Variable> vars = getVariablesByType(type);
    for (var v in vars) {
      anno = _findAnnotationForType<T>(type, v, converter);
      if (anno != null) {
        if (annotationTypeCheck) {
          bool hasMatchingType =
              v.element.isOfSameTypeAsTypeArgumentFromObject(anno.object, lessStrict: true, allowDynamic: true);
          if (!hasMatchingType) styleKeyTypeMismatch(v, anno.object.type);
        }

        v._cache._inject(anno);
      }
    }
  }

  void resolveTypes(ResolvedLibraryResult resolvedLib, {FieldType? type}) {
    type ??= FieldType.MERGED;

    List<Variable> vars = getVariablesByType(type);
    for (var v in vars) {
      v.resolveType(resolvedLib);
    }
  }

  @protected
  AnnotatedElement<T>? _findAnnotationForType<T>(FieldType type, Variable v, AnnotationConverter<T> converter) {
    switch (type) {
      case FieldType.FIELD:
        return _getAnnotation(null, v, converter);
      case FieldType.CONSTRUCTOR_PARAM:
        return _getAnnotation(v, null, converter);
      case FieldType.MERGED:
        return _findWeightedAnnotation(v, converter);
    }
  }

  /// returns the annotation for [parameter] and falls back to the annotation of the corresponding field annotation
  AnnotatedElement<T>? _findWeightedAnnotation<T>(Variable parameter, AnnotationConverter<T> converter) {
    for (var field in fields) {
      if (parameter == field) {
        return _getAnnotation<T>(parameter, field, converter);
      }
    }
    return null;
  }
}

/// returns either the annotation of [parameter] or [field]
///
/// [parameter] annotations are weighted over [field] annotations.
AnnotatedElement<T>? _getAnnotation<T>(Variable? parameter, Variable? field, AnnotationConverter<T> converter) {
  AnnotatedElement<T>? anno;
  if (parameter != null) anno = parameter._cache._getAnnotatedElement<T>(parameter.element, converter);
  AnnotatedElement<T>? fieldAnno;
  if (field != null) fieldAnno = field._cache._getAnnotatedElement<T>(field.element, converter);

  return anno ?? fieldAnno;
}
