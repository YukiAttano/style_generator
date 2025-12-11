
import "package:analyzer/dart/element/element.dart";


extension TypeParameterElementListExtension on List<TypeParameterElement> {
  String typesToString() {
    if (isEmpty) return "";

    return "<${join(",")}>";
  }
}
