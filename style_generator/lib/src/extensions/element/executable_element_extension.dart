import "package:analyzer/dart/element/element.dart";

extension ExecutableElementExtension on ExecutableElement {
  /// Fallback name-lookup if AST-lookup fails
  ///
  /// Due to the nature of [Element]s, this method does not recognize prefix name imports
  /// (Hence why we search the AST).
  ///
  /// The AST-lookup should always work and
  /// this function exists solely to have a generalized backup
  String? getFunctionName() {
    String? callbackName;
    ExecutableElement? function = this;

    if (function.isStatic) {
      switch (function.kind) {
        case ElementKind.METHOD:
          callbackName = "${function.enclosingElement?.displayName ?? ""}.${function.displayName}";
        case ElementKind.FUNCTION:
          callbackName = function.displayName;
      }
    } else {
      switch (function.kind) {
        case ElementKind.CONSTRUCTOR:
          callbackName = function.displayName;
      }
    }

    return callbackName;
  }
}
