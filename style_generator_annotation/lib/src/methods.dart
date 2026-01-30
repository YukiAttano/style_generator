/// @docImport "annotations/style_key.dart";
library;

/// will always return [other]
T noMerge<T>(T a, T other) => other;

/// will always return [b]
T noLerp<T>(T? a, T? b, double t) => b as T;

/// will return [a] for the first half of [t], then [b]
T halfLerp<T>(T? a, T? b, double t) => (t < 0.5 ? a : b) as T;