import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/type.dart";

extension ClassElementExtension on ClassElement {
  ConstructorElement? getPrimaryConstructor() => constructors.getPrimaryConstructor();

  List<FieldElement> getPropertyFields() {
    List<FieldElement> f = fields.getPropertyFields();

    for (var s in allSupertypes) {
      _RecursiveSupertypeLookupExtension(s).getFields(f);
    }

    return f;
  }
}

extension _RecursiveSupertypeLookupExtension on InterfaceType {
  void getFields(List<FieldElement> list) {
    list.addAll(element.fields.getPropertyFields());

    for (var s in allSupertypes) {
      s.getFields(list);
    }
  }
}

extension ConstructorElementListExtension on List<ConstructorElement> {
  /// tries to best guess the primary constructor
  ConstructorElement? getPrimaryConstructor() {
    ConstructorElement? primaryConstructor;

    for (var c in this) {
      if (primaryConstructor == null) {
        primaryConstructor = c;
      } else if (c.isPublic) {
        if (primaryConstructor.isPrivate) {
          primaryConstructor = c;
        }
      }

      if (c.name == "new") {
        break;
      }
    }

    return primaryConstructor;
  }
}

extension FieldElementListExtension on List<FieldElement> {
  List<FieldElement> getPropertyFields() {
    List<FieldElement> list = [];

    for (var f in this) {
      if (f.isStatic || f.isSynthetic || f.isPrivate) {
        continue;
      }

      list.add(f);
    }

    return list;
  }
}
