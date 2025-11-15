import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";

class ClassMethod {
  final InterfaceType type;
  final MethodElement element;

  String get name => element.displayName;
  bool get isStatic => element.isStatic;
  ClassElement get clazz => element.enclosingElement! as ClassElement;

  late Map<String, DartType> typeArgs = _getTypeArgs();
  late String types = _getTypes();
  late String methodHead = _getMethodHead();

  ClassMethod({required this.type, required this.element});

  /// returns a map of the type parameter (like T, K) from [clazz]
  /// and the corresponding type argument (like int, String) from [type]
  Map<String, DartType> _getTypeArgs() {
    return Map.fromIterables(clazz.typeParameters.map((e) => e.displayName), type.typeArguments);
  }

  String _getTypes() {
    List<TypeParameterElement> typeParameters = element.typeParameters;

    List<String> typeList = [];
    String types = "";
    if (typeParameters.isNotEmpty) {
      for (var t in typeParameters) {
        typeList.add(typeArgs[t.displayName]?.getDisplayString() ?? "Object?");
      }

      types = "<${typeList.join(",")}>";
    }

    return types;
  }

  /// The beginning of the method prototype
  ///
  /// The [element] type parameter are replaced by the [type] type arguments
  /// ```dart
  /// Example<int, String> mixedTypesExample;
  ///
  /// class Example<T, K> {
  ///   // Example.lerp<String, int>
  ///   static Example<K, T> lerp<K, T>(Example<K, T> a, Example<T, K> b, double t) {}
  ///
  ///   // lerp<String, int>
  ///   Example<K, T> lerp<K, T>(Example<K, T> a, Example<T, K> b, double t) {}
  /// }
  /// ```
  ///
  /// ```text
  /// The returned name will put the type _arguments_ (int, String)
  /// at the correct position of the type _parameter_ (T, K)
  /// ```
  String _getMethodHead() {
    String head;

    if (element.isStatic) {
      String className = clazz.displayName;

      head = "$className.$name$types";
    } else {
      head = "$name$types";
    }

    return head;
  }


}
