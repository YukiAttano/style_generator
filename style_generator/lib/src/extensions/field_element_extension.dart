import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";

extension FieldElementExtension on FieldElement {
  TypeAnnotation? getPrefixedType(ResolvedLibraryResult resolvedLib) {
    FragmentDeclarationResult? fragmentDeclaration = resolvedLib.getFragmentDeclaration(firstFragment);

    AstNode? node = fragmentDeclaration?.node.parent;
    if (node is VariableDeclarationList) {
      return node.type;
    }

    return null;
  }
}
