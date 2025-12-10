/// @docImport "../annotations/copy_with_config.dart";
/// @docImport "../annotations/style_config.dart";
library;

/// Allows other classes to depend on 'C' as a Config with 'A' as annotation like [StyleConfig] and [CopyWithConfig]
// ignore: one_member_abstracts .
abstract class _BaseConfig<C extends _BaseConfig<C, A>, A> {
  _BaseConfig apply(A config);
}

// Simplify _BaseConfig
/// Allows other classes to depend on a 'Config' with 'A' as annotation like [StyleConfig] and [CopyWithConfig]
abstract interface class Config<A> extends _BaseConfig<Config<A>, A> {
  @override
  Config<A> apply(A config);
}
