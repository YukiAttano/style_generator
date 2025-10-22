part of "variable.dart";

/// merges the annotations of constructor parameters and class fields together.
///
/// Annotations on [constructorParams] are weighted over [fields] annotations.
///
/// We may speak of merging, but annotations are in fact replaced and not merged.
class VariableHandler {
  final List<Variable> constructorParams;
  final List<Variable> fields;

  late final List<Variable> _merged = List.of(constructorParams.map((e) => Variable(element: e.element)));

  List<Variable> get merged => UnmodifiableListView(_merged);

  VariableHandler({required this.constructorParams, required this.fields});

  void build<T>(AnnotationConverter<T> converter) {
    AnnotatedElement<T>? anno;
    for (var v in merged) {
      anno = _findAnnotation<T>(v, converter);
      if (anno != null) v._cache._inject(anno);
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
