///@docImport "package:build/build.dart";
library;

import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/element/element.dart";
import "package:build/build.dart";

extension ResolvedLibraryResultExtension on ResolvedLibraryResult {

  ClassDeclaration? findClassDeclarationFor(ClassElement clazz) {
    for (var unitResult in units) {
      for (var declaration in unitResult.unit.declarations) {
        if (declaration is ClassDeclaration && declaration.declaredFragment == clazz.firstFragment) {
          return declaration;
        }
      }
    }

    return null;
  }

  ConstructorDeclaration? findConstructorDeclarationFor(ConstructorElement constructor) {
    for (var unitResult in units) {
      for (var declaration in unitResult.unit.declarations) {
        if (declaration is ClassDeclaration) {
          for (var member in declaration.members) {
            if (member is ConstructorDeclaration) {
              return member;
            }
          }
        }
      }
    }

    return null;
  }

  /// will resolve `fragment` to its declaration `R`
  ///
  /// It must be contained in this library, otherwise use [Resolver.astNodeFor]
  R? resolve<R>(Fragment? fragment) {
    if (fragment == null) return null;

    return getFragmentDeclaration(fragment)?.node as R?;
  }

  List<PartDirective> getPartDirectives() {

    List<PartDirective> list = [];

    for (var u in units) {
      for (var directive in u.unit.directives) {
        if (directive is PartDirective) {
          list.add(directive);
        }
      }
    }

    return list;
  }

  bool containsPart(AssetId sourceId, AssetId lookupPart) {
    List<PartDirective> parts = getPartDirectives();

    AssetId partId;
    for (var p in parts) {
      partId = AssetId.resolve(Uri.parse(p.uri.stringValue!), from: sourceId);

      return partId.uri.toString() == lookupPart.uri.toString();
    }

    return false;
  }
}
