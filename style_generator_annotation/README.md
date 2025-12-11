[![Pub Package](https://img.shields.io/pub/v/style_generator_annotation)](https://pub.dev/packages/style_generator_annotation)

This package requires [style_generator](https://pub.dev/packages/style_generator) 
to be a dependency to build code.
Docs and Examples can be found there.

# Getting started
```shell
dart pub add style_generator_annotation 
dart pub add dev:style_generator 
dart pub add dev:build_runner
```

or the same in one line:
```shell
dart pub add style_generator_annotation dev:style_generator dev:build_runner
```

For even easier generation, use the [Style Generator Templates for Flutter](https://plugins.jetbrains.com/plugin/28833-style-generator-templates-for-flutter) Plugin for Android Studio

# Annotations

- Style and StyleKey (for generating ThemeExtension classes)
- CopyWith and CopyWithKey (for generating CopyWith Extensions only)