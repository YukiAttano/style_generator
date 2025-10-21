import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:style_generator/src/data/annotation_converter.dart';
import 'package:style_generator/src/extensions/element_extension.dart';

import '../data/annotated_element.dart';

part 'variable_handler.dart';

class Variable {
  final VariableElement element;

  DartType get type => element.type;

  String? get name => element.name;

  String get displayName => element.displayName;

  bool get isPublic => element.isPublic;

  bool get isPrivate => element.isPrivate;

  bool get isStatic => element.isStatic;

  final _Cache _cache;

  Variable._({required this.element, _Cache? cache}) : _cache = cache ?? _Cache();

  Variable({required VariableElement element}) : this._(element: element);

  T? getAnnotationOf<T>(AnnotationConverter<T> converter) => _cache.getAnnotation<T>(element, converter);

  @override
  bool operator ==(Object other) {
    if (other is! Variable) return false;

    return identical(this, other) || type == other.type && name == other.name && displayName == other.displayName;
  }

  @override
  int get hashCode => Object.hash(type, name, displayName);

  @override
  String toString() => element.toString();
}

class _Cache {

  final Map<Type, AnnotatedElement<Object?>> map;

  _Cache({Map<Type, AnnotatedElement<Object?>>? map}) : map = map ?? {};

  AnnotatedElement<T>? _getAnnotatedElement<T>(VariableElement element, AnnotationConverter<T> converter) {
    AnnotatedElement<T>? annotation = map[T] as AnnotatedElement<T>?;

    if (annotation == null) {
      annotation = element
          .getAnnotationsOf<T>(converter)
          .firstOrNull;
      if (annotation != null) _inject<T>(annotation);
    }

    return annotation;
  }

  T? getAnnotation<T>(VariableElement element, AnnotationConverter<T> converter) {
    return _getAnnotatedElement<T>(element, converter)?.annotation;
  }

  void _inject<T>(AnnotatedElement<T>? annotation) {
    if (annotation == null) return;
    map[T] = annotation;
  }

  _Cache copy() {
    return _Cache(map: Map.of(map));
  }
}