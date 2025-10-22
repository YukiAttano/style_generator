extension StringConstructorExtension on String {

  /// returns "new" if the string is empty.
  ///
  /// this is used to find the default constructor
  String get asConstructorName {
    if (isEmpty) return "new";
    return this;
  }
}
