[![Pub Package](https://img.shields.io/pub/v/style_generator)](https://pub.dev/packages/style_generator)

This package is considered stable and will jump to version 1.0.0 after a testing period.

Generates ThemeExtensions for your Style Classes

| Before                                   | After                                 |
|------------------------------------------|---------------------------------------|
| ![before.png](../ressources/before.png)  | ![after.png](../ressources/after.png) |

# Getting Started

```shell
dart pub add style_generator_annotation
dart pub add dev:style_generator
dart pub add dev:build_runner
```

## Template Plugin

For even easier generation, use the [Style Generator Templates for Flutter](https://plugins.jetbrains.com/plugin/28833-style-generator-templates-for-flutter) Plugin for Android Studio

# ThemeExtensions

## Minimum Example:
```dart
import 'package:flutter/material.dart';
// add import
import 'package:style_generator_annotation/style_generator_annotation.dart';

// add part file: your_file_name.style.dart
part 'some_style.style.dart';

// add Style annotation and Mixin _$YourClass
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
  // just add the fields and a constructor to assign them
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final Color? color;
  final Color? selectionColor;

  const SomeStyle({this.titleStyle, this.color, this.subtitleStyle, this.selectionColor});
}
```

## Fallback and of() Constructor:

This package supports generating a quick constructor to retrieve your Style from BuildContext.

```dart
import "package:flutter/widgets.dart";

class SomeWidget extends StatelessWidget {
  final SomeStyle? style;

  const SomeWidget({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    // retrieve your custom style from context, backed by your SomeStyle.fallback() design.
    SomeStyle s = SomeStyle.of(context, style);

    return const Placeholder();
  }
}
```

```dart
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
  
  // ... see minimal example at the top
  
  factory SomeStyle.fallback(BuildContext context, {String? something}) {
    ThemeData theme = Theme.of(context);
    ColorScheme scheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;

    return SomeStyle(
      titleStyle: textTheme.titleSmall,
      subtitleStyle: textTheme.bodySmall,
      color: scheme.secondaryContainer,
      selectionColor: scheme.primaryContainer,
    );
  }

  // add YourClass.of(BuildContext context) as a factory constructor
  factory SomeStyle.of(BuildContext context, [SomeStyle? style]) => _$SomeStyleOf(context, style);

  // That will generate this method
  SomeStyle _$SomeStyleOf(BuildContext context, [SomeStyle? style]) {
    SomeStyle s = SomeStyle.fallback(context);
    s = s.merge(Theme.of(context).extension<SomeStyle>());
    s = s.merge(style);

    return s;
  }
}
```

## Positional and Named Parameter

A mix of positional and named parameter are supported.

```dart
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final Color? color;
  final Color? selectionColor;

  const SomeStyle(this.titleStyle, this.color, {this.subtitleStyle, this.selectionColor});
}
```

Additionally non-nullable parameter and typed parameter are also supported.

```dart
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  // Types that have a lerp function, whether static or not are used for lerp() automatically.
  // Here, the lerp() method from Some<T, K> will be used.
  final Some<Color, double>? color;
  final Color? selectionColor;

  const SomeStyle(this.titleStyle, this.color, {required this.subtitleStyle, this.selectionColor});
}

class Some<T, K> {
  final T color;
  final K something;

  const Some(this.color, this.something);

  Some<T, K>? lerp(Some<T, K>? a, Some<T, K>? b, double t) {
    return b;
  }
}
```

# Annotations

## Style
The Style annotation allows customizing the generation of the style class.
For example, you can disable the .copyWith generation and use another Package for its generation.

See the Style documentation for more info.

```dart
@Style(constructor: "_", fallback: "custom", genCopyWith: true, genMerge: true, genLerp: true, genOf: true, suffix: "Generated")
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyleGenerated {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  // lerp method from Some<T, K> will be used
  final Some<Color, double>? color;
  final Color? selectionColor;

  const SomeStyle(this.titleStyle, this.color, {required this.subtitleStyle, this.selectionColor});
  
  factory SomeStyle.of(BuildContext context, [SomeStyle? style]) => _$SomeStyleGeneratedOf(context, style);
}

```

You can customize the default behavior in your build.yml

```yaml
targets:
  $default:
    builders:
      style_generator|style_builder:
        enabled: true
        options:
          constructor: null     # The constructor for .copyWith and .lerp to use. The default is `null`
          fallback: "fallback"  # The constructor for .of to use. The default is `null`
          gen_copy_with: true   # whether .copyWith should be generated, The default is `true`
          gen_merge: true       # whether .merge should be generated, The default is `true`
          gen_lerp: true        # whether .lerp should be generated, The default is `true`
          gen_of: null          # whether .of should be generated, The default is `null` (will only generate if the fallback constructor and a factory .of() constructor is found)
          suffix: null          # an optional suffix for the generated mixin and .of method
```

## StyleKey\<T>

Every field and constructor parameter can be further configured with @StyleKey\<T>()

```dart
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
 
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @StyleKey(inCopyWith: false, inLerp: false, inMerge: false)
  final Color? color;
  final Color? selectionColor;

  const SomeStyle({
    this.titleStyle, 
    this.color, 
    this.subtitleStyle,
    @StyleKey(inCopyWith: false, inLerp: false, inMerge: false)
    this.selectionColor,
  });
}
```

Only StyleKeys on fields and the constructor matching Style.constructor are considered.

Do note, StyleKeys on the constructor override configurations on the field without further warning.

## Custom Lerp Functions

Sometimes, custom lerp functions are required.

The generator will consider lerpDouble() for integer, double and num fields by default.
It uses a lerpDuration for Darts Duration class.
For all other cases, it searches for a .lerp() method inside the types class and applies that.
If nothing is found, .lerp() will not lerp the field (and a warning is printed).

Other custom typed .lerp() functions can be applied with StyleKeys.
(The custom method must be static or a top level method).

```dart
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
 
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  // The function must match the type of the StyleKey. (Which itself should match the type of the field)
  @StyleKey<WidgetStateProperty<double?>?>(lerp: lerpWidgetStateProperty)
  final WidgetStateProperty<double?>? elevation;
  
  // Here, a custom color lerp function is used
  @StyleKey<Color?>(lerp: customColorLerp)
  final Color? color;
  final Color? selectionColor;

  const SomeStyle({
    this.titleStyle, 
    this.color, 
    this.elevation,
    this.subtitleStyle,
    this.selectionColor,
  });

  static WidgetStateProperty<double?>? lerpWidgetStateProperty(
      WidgetStateProperty<double?>? a,
      WidgetStateProperty<double?>? b,
      double t,
      ) {
    return WidgetStateProperty.lerp<double?>(a, b, t, lerpDouble);
  }
}

Color? customColorLerp(Color? a, Color? b, double t) => b;
```

## Custom Merge Functions

Sometimes, like i guess never, custom merge functions are required.

For example, if you don't want to apply the default merge() behavior of a TextStyle.

(The custom method must be static or a top level method).

```dart
@Style()
class SomeStyle extends ThemeExtension<SomeStyle> with _$SomeStyle {
 
  // The function must match the type of the StyleKey. (Which itself should match the type of the field)
  @StyleKey<TextStyle?>(merge: noMerge)
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final Color? color;
  final Color? selectionColor;

  const SomeStyle({
    this.titleStyle, 
    this.color, 
    this.subtitleStyle,
    this.selectionColor,
  });
}
```

# Feedback

Any feedback is welcome :)