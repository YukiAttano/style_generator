import "package:analyzer/dart/element/element.dart";

class FieldMapResult {
  final List<FieldElement> fields;

  bool get isEmpty => fields.isEmpty;
  bool get isNotEmpty => fields.isNotEmpty;

  FieldMapResult.empty() : fields = [];

  const FieldMapResult.list(this.fields);

  FieldMapResult.value(FieldElement? element) : fields = [?element];

  void add(FieldElement element) => fields.add(element);
  void addAll(List<FieldElement> elements) => fields.addAll(elements);
}
