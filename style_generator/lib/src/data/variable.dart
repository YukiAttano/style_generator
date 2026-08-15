import "dart:async";

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";
import "package:build/build.dart";
import "package:collection/collection.dart";
import "package:meta/meta.dart";

import "../data/annotated_element.dart";
import "../extensions/constructor_declaration_extension.dart";
import "../extensions/dart_type_extension.dart";
import "../extensions/element/class_element_extension.dart";
import "../extensions/element/element_extension.dart";
import "../extensions/element/variable_element_extension.dart";
import "../extensions/resolved_library_result_extension.dart";
import "annotation_converter/annotation_converter.dart";
import "field_map_result.dart";
import "logger.dart";
import "resolved_type.dart";

part "variable_handler.dart";

class Variable {
  final VariableElement element;

  final List<FieldElement> fieldElements;

  /// returns the preferred field from [fieldElement]
  FieldElement? get fieldElement => preferField(null, null);

  FormalParameterElement? get _asParameter {
    assert(
      element is FormalParameterElement,
      "Accessed $element as FormalParameterElement but it is ${element.runtimeType}",
    );
    return element is FormalParameterElement ? element as FormalParameterElement : null;
  }

  /// if this is null, [resolveType] will fail.
  ///
  /// A library element is defined to be only null on pseudo elements like [MultiplyDefinedElement]
  LibraryElement? get library => element.library;

  DartType get type => element.type;

  /*
  DartType get classType {
    assert(
      resolvedType.type is! TypeParameterType || type is! TypeParameterType,
      "The found type is a generic type like 'T' or 'K' etc. but we expected to have a defined class",
    );

    if (resolvedType.type is TypeParameterType) return type;

    return resolvedType.type;
  }*/

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

  Variable._({required this.element, required this.fieldElements, _Cache? cache}) : _cache = cache ?? _Cache();

  /// A generalized representation about (mainly) [FormalParameterElement] and [FieldElement]
  ///
  /// This class will also be used to merge annotations on constructor parameters and fields.
  /// In this case, [fieldElement] must be set to not loose the access to the fields information
  /// like its (probably) prefixed type (accessible via [resolveType]).
  ///
  /// if [element] is of type [FieldElement], [fieldElement] is ignored
  factory Variable({required VariableElement element, FieldElement? fieldElement}) {
    return Variable.fromList(element: element, fieldElements: [?fieldElement]);
  }

  factory Variable.fromList({required VariableElement element, List<FieldElement> fieldElements = const []}) {
    List<FieldElement> elements = [?_getFieldElement(element)];
    if (elements.isEmpty) elements = fieldElements;

    return Variable._(element: element, fieldElements: elements.toSet().toList());
  }

  /// This is not exhaustive
  ///
  /// To correctly find all elements, [VariableHandler] with a full list of fields is required
  static FieldElement? _getFieldElement(VariableElement element, [int depth = 0]) {
    switch (element) {
      case FieldElement():
        return element;
      case FieldFormalParameterElement():
        return element.field;
      case SuperFormalParameterElement():
        return _getFieldElement(element.superConstructorParameter!, depth + 1);
    }

    return null;
  }

  T? getAnnotationOf<T>(AnnotationConverter<T> converter) => _cache.getAnnotation<T>(element, converter);

  /// will return the (prefixed) type of [fieldElement]
  ResolvedType resolveType(ResolvedLibraryResult resolvedLib) {
    ResolvedType? resolvedType = _resolvedType;

    if (resolvedType == null) {
      if (fieldElements.isEmpty) {
        resolvedType = ResolvedType(
          library: library,
          type: type,
          typeAnnotation: null,
          prefixReference: null,
          importDirective: null,
          typeInformation: const [],
        );
      } else {
        if (fieldElements.length == 1) {
          resolvedType = ResolvedType.resolve(resolvedLib: resolvedLib, element: fieldElements.first);
        } else {
          List<ResolvedType> resolved = [];
          ResolvedType? current;
          ResolvedType? type;
          for (var field in fieldElements) {
            current = ResolvedType.resolve(resolvedLib: resolvedLib, element: field);
            resolved.add(current);
            if (type == null) {
              type = current;
            } else {
              var first = type.type.extensionTypeErasure;
              var second = current.type.extensionTypeErasure;

              if (first != second) {
                bool firstIsSubtypeOfSecond = first.isSubtypeOf(resolvedLib.element, second);
                bool secondIsSubtypeOfFirst = second.isSubtypeOf(resolvedLib.element, first);
                if (!firstIsSubtypeOfSecond && !secondIsSubtypeOfFirst) {
                  throw Exception(
                    "The parameter $element is mapped against multiple fields $fieldElements, and two of them were different",
                  );
                } else {
                  if (secondIsSubtypeOfFirst) type = current;
                }
              }
            }
          }

          resolvedType = type!;
        }
      }

      if (resolvedType.type is TypeParameterType) {
        resolvedType = resolvedType.overwriteType(element.type);
      }

      _resolvedType = resolvedType;
    }

    return resolvedType;
  }

  /// Searches for the field with the displayName [name] in [fieldElements].
  ///
  /// If the preferred [name] is null or not found, the first element is used
  FieldElement? preferField(String? name, String? className) {
    // ignore: avoid_bool_literals_in_conditional_expressions for readability purpose
    assert(name != null ? className != null : true, "when 'name' is given, a class name is required for logging");

    FieldElement? fallback = fieldElements.firstOrNull;

    if (fieldElements.length > 1) {
      String privateName = "_$displayName";
      FieldElement? preferredNameMatch;
      FieldElement? sameNameMatch;
      FieldElement? privateNameMatch;

      for (var f in fieldElements) {
        if (f.displayName == name) {
          preferredNameMatch = f;
        } else if (f.displayName == displayName) {
          sameNameMatch = f;
        } else if (f.displayName == privateName) {
          privateNameMatch = f;
        }
      }

      if (name != null && preferredNameMatch == null) preferredFieldNotFound(this, name, clazz: className!);

      return preferredNameMatch ?? sameNameMatch ?? privateNameMatch ?? fallback;
    }

    return fallback;
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
