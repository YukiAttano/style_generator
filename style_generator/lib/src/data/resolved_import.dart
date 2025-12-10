class ResolvedImport {
  final String prefix;
  final Uri uri;

  bool get hasPrefix => prefix.isNotEmpty;

  const ResolvedImport({this.prefix = "", required this.uri});

  @override
  String toString() {
    if (!hasPrefix) {
      return "'$uri'";
    } else {
      return "'$uri' as $prefix";
    }
  }

  @override
  int get hashCode => Object.hash(prefix, uri);

  @override
  bool operator ==(Object other) {
    if (other is! ResolvedImport) return false;

    return identical(this, other) || prefix == other.prefix && uri == other.uri;
  }
}
