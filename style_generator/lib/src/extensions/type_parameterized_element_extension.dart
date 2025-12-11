import "package:analyzer/dart/element/element.dart";

import "type_parameter_element_list_extension_.dart";

extension TypeParameterizedElementExtension on TypeParameterizedElement {
  String getTypedName({String suffix = ""}) {
    String types = typeParameters.typesToString();

    return "$displayName$suffix$types";
  }
}
