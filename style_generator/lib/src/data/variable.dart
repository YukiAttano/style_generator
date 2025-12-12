import "dart:convert";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:collection/collection.dart";

import "../data/annotated_element.dart";
import "../extensions/constructor_declaration_extension.dart";
import "../extensions/element/class_element_extension.dart";
import "../extensions/element/element_extension.dart";
import "../extensions/element/variable_element_extension.dart";
import "../extensions/resolved_library_result_extension.dart";
import "annotation_converter/annotation_converter.dart";
import "logger.dart";
import "resolved_type.dart";

import 'dart:core' hide print;
import 'dart:core' as c show print;

part "variable_handler.dart";

class Variable {
  final VariableElement element;

  final FieldElement? fieldElement;

  FormalParameterElement? get _asParameter {
    assert(
      element is FormalParameterElement,
      "Accessed $element as FormalParameterElement but it is ${element.runtimeType}",
    );
    return element is FormalParameterElement ? element as FormalParameterElement : null;
  }

  /// if this is null, [resolveType] will fail
  ///
  /// a library element is defined to be only null on pseudo elements like [MultiplyDefinedElement]
  LibraryElement? get library => element.library;

  DartType get type => element.type;

  // ElementKind get kind => element.kind;

  String? get name => element.name;

  String get displayName => element.displayName;

  bool get isPublic => element.isPublic;

  bool get isPrivate => element.isPrivate;

  bool get isStatic => element.isStatic;

  bool get isNamed => _asParameter?.isNamed ?? false;

  bool get isPositional => _asParameter?.isPositional ?? false;

  bool get isOptional => _asParameter?.isOptional ?? false;

  bool get isRequired => _asParameter?.isRequired ?? false;

  final _Cache _cache;

  ResolvedType? _resolvedType;

  ResolvedType get resolvedType {
    assert(_resolvedType != null, "resolvedType was never resolved. Call resolveType() first");
    return _resolvedType!;
  }

  Variable._({required this.element, required this.fieldElement, _Cache? cache}) : _cache = cache ?? _Cache();

  /// A generalized representation about (mainly) [FormalParameterElement] and [FieldElement]
  ///
  /// This class will also be used to merge annotations on constructor parameters and fields.
  /// In this case, [fieldElement] must be set to not loose the access to the fields information
  /// like its (probably) prefixed type (accessible via [resolveType]).
  ///
  /// if [element] is of type [FieldElement], [fieldElement] is ignored
  Variable({required VariableElement element, FieldElement? fieldElement})
      : this._(element: element, fieldElement: _getFieldElement(element) ?? fieldElement);

  static FieldElement? _getFieldElement(VariableElement element) {
    switch (element) {
      case FieldElement():
        return element;
      case FieldFormalParameterElement():
        return element.field;
      case SuperFormalParameterElement():
        return _getFieldElement(element.superConstructorParameter!);
    }

    return null;
  }

  T? getAnnotationOf<T>(AnnotationConverter<T> converter) => _cache.getAnnotation<T>(element, converter);

  /// will return the (prefixed) type of [fieldElement]
  ResolvedType resolveType(ResolvedLibraryResult resolvedLib) {
    ResolvedType? resolvedType = _resolvedType;

    if (resolvedType == null) {
      if (fieldElement == null) {
        resolvedType = ResolvedType(
          library: library!,
          type: type,
          typeAnnotation: null,
          prefixReference: null,
          importDirective: null,
        );
      } else {
        resolvedType = ResolvedType.resolve(resolvedLib: resolvedLib, element: fieldElement!);
      }

      _resolvedType = resolvedType;
    }

    return resolvedType;
  }

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
      annotation = element.getAnnotationsOf<T>(converter).firstOrNull;
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
