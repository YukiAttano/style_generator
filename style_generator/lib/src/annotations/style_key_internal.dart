/// @docImport "package:style_generator_annotation/style_generator_annotation.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/dart/element/visitor2.dart";
import "package:build/build.dart";

import "../data/logger.dart";
import "../extensions/dart_object_extension.dart";

/// The internal representation of [StyleKey]
///
/// [StyleKey] forces the [lerp] method to be be correctly typed,
/// while this internal representation just holds the function name.
class StyleKeyInternal<T> {
  final bool inCopyWith;
  final bool inMerge;
  final bool inLerp;
  final String? lerp;
  final String? merge;

  const StyleKeyInternal({
    required this.inCopyWith,
    required this.inMerge,
    required this.inLerp,
    required this.lerp,
    required this.merge,
  });

  Map<String, Object?> toJson() {
    return {
      "inCopyWith": inCopyWith,
      "inMerge": inMerge,
      "inLerp": inLerp,
      "lerp": lerp,
      "merge": merge,
    };
  }
}

StyleKeyInternal<T> createStyleKey<T>(ResolvedLibraryResult resolved, CompilationUnit unit, Map<String, DartObject?> map) {
  ExecutableElement? lerp = map["lerp"]?.toFunctionValue();
  ExecutableElement? merge = map["merge"]?.toFunctionValue();

  if (lerp != null) {
    //resolved.getFragmentDeclaration(lerp.firstFragment,);


    // var result = resolved.getFragmentDeclaration(lerp.firstFragment);
    //
    // warn("CHECKING $lerp "
    //     "\nfragment:${result?.fragment}"
    //     "\nnode:${result?.node}"
    //     "\ntype:${result.runtimeType}");
    //
    // TestVisitor v = TestVisitor(element: lerp);
    // String? result;
    //
    // for (var declaration in unit.declarations) {
    //   var r = declaration.accept(v);
    //   if (r != null) warn(r);
    // }
  }




  return StyleKeyInternal(
    inLerp: map["inLerp"]!.toValue()! as bool,
    inMerge: map["inMerge"]!.toValue()! as bool,
    inCopyWith: map["inCopyWith"]!.toValue()! as bool,
    lerp: _getFunctionName(lerp),
    merge: _getFunctionName(merge),
  );
}

String? _getFunctionName(ExecutableElement? function) {
  String? callbackName;
  if (function != null && function.isStatic) {
    switch (function.kind) {
      case ElementKind.METHOD:
        callbackName = "${function.enclosingElement?.displayName ?? ""}.${function.displayName}";
      case ElementKind.FUNCTION:
        callbackName = function.displayName;
    }
  }

  return callbackName;
}


class TestVisitor extends RecursiveAstVisitor<String?>  {
  final ExecutableElement? element;

  const TestVisitor({required this.element});

  @override
  String? visitAnnotation(Annotation node) {
    //warn("\n-----\nnode:${node}\nelement:${node.element}\ngiven:$element");


    return super.visitAnnotation(node);
  }
/*
  @override
  String? visitVariableDeclaration(VariableDeclaration node) {
    warn("\n-----VAR\nnode:${node}\nparent:${node.parent}\ngiven:$element");


    return super.visitVariableDeclaration(node);
  }*/

  @override
  String? visitFieldDeclaration(FieldDeclaration node) {
    warn("\n-----Field\nnode:${node}\nchildren:${node.childEntities}\nfields:${node.fields}\ngiven:$element");

    TypeAnnotation? type = node.fields.type;
    warn("FIELD ${type?.beginToken} $type");

    return super.visitFieldDeclaration(node);
  }


}

class TestElementVisitor extends RecursiveElementVisitor2<void>  {

  @override
  void visitTypeParameterElement(TypeParameterElement element) {
    warn("\nVISIT ${element}");

    super.visitTypeParameterElement(element);
  }

  @override
  void visitPrefixElement(PrefixElement element) {
    warn("\nVISIT ${element}");

    super.visitPrefixElement(element);
  }


  @override
  void visitGenericFunctionTypeElement(GenericFunctionTypeElement element) {
    warn("\nVISIT ${element}");

    super.visitGenericFunctionTypeElement(element);
  }
}