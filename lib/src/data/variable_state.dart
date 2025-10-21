part of 'variable.dart';

class VariableState {

  final List<Variable> constructorParams;
  final List<Variable> fields;

  late final List<Variable> _merged = List.of(constructorParams.map((e) => Variable(element: e.element)));
  List<Variable> get merged => UnmodifiableListView(_merged);

  VariableState({required this.constructorParams, required this.fields});

  void build<T>(AnnotationBuilder<T> builder) {
    AnnotatedElement<T>? anno;
    for (var v in merged) {
      anno = _findAnnotation<T>(v, builder);
      if (anno != null) v._cache._inject(anno);
    }
  }

  AnnotatedElement<T>? _findAnnotation<T>(Variable parameter, AnnotationBuilder<T> builder) {
    for (var field in fields) {
      if (parameter == field) {
        return _getAnnotation<T>(parameter, field, builder);
      }
    }
    return null;
  }
}

AnnotatedElement<T>? _getAnnotation<T>(Variable parameter, Variable field, AnnotationBuilder<T> builder) {
  AnnotatedElement<T>? anno = parameter._cache._getAnnotatedElement<T>(parameter.element, builder);
  AnnotatedElement<T>? fieldAnno = field._cache._getAnnotatedElement<T>(field.element, builder);

  return anno ?? fieldAnno;
}