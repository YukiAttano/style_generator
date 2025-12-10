

abstract class _BaseConfig<C extends _BaseConfig<C, A>, A> {
  _BaseConfig apply(A config);
}

abstract interface class Config<A> extends _BaseConfig<Config<A>, A> {
  Config<A> apply(A config);
}
