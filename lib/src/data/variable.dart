import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:style_generator/src/data/annotation_builder.dart';
import 'package:style_generator/src/extensions/element_extension.dart';

import '../data/annotated_element.dart';

class Variable {
  final VariableElement element;

  DartType get type => element.type;

  String? get name => element.name;

  String get displayName => element.displayName;

  bool get isPublic => element.isPublic;

  bool get isPrivate => element.isPrivate;

  bool get isStatic => element.isStatic;

  const Variable({required this.element});

  List<AnnotatedElement<T>> getAnnotationsOf<T>(AnnotationBuilder<T> builder) => element.getAnnotationsOf(builder);

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
