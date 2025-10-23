[![Pub Package](https://img.shields.io/pub/v/style_generator)](https://pub.dev/packages/style_generator)

Generates ThemeExtensions for your Style Classes

| Before                                                                               | After                                                                              |
| ------------------------------------------------------------------------------------ |------------------------------------------------------------------------------------|
| ![before](https://github.com/YukiAttano/style_generator/blob/main/assets/before.png) | ![after](https://github.com/YukiAttano/style_generator/blob/main/assets/after.png) |

# Getting Started



# ThemeExtensions

Minimum Example:
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

Fallback and of() Constructor:

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

  // This will generate this method
  SomeStyle _$SomeStyleOf(BuildContext context, [SomeStyle? style]) {
    SomeStyle s = SomeStyle.fallback(context);
    s = s.merge(Theme.of(context).extension<SomeStyle>());
    s = s.merge(style);

    return s;
  }
}
```