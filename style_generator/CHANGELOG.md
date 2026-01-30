## 0.2.3

* Support `analyzer: ">=8.1.0 <11.0.0"`

## 0.2.2

* change StyleKey's type parameter is to optional
* remove type parameter from CopyWithKey

## 0.2.1

* add CopyWith and CopyWithKey annotation

## 0.2.0

* add warnings if @StyleKey\<Type\>s type does not match the annotated fields type
* add support for Constructor callbacks in StyleKey.lerp and StyleKey.merge 
* add prefixed import support (e.g. `import 'package:some/some.dart' as some`)

## 0.1.4

* Fix finding functions (like lerp and merge) through being expected by extended or inherited classes

## 0.1.3

* Improve docs

## 0.1.2

* Add StyleKey.merge override parameter
* Add Warning if no lerp() method could be found

## 0.1.1

* Add IntelliJ/Android Studio plugin to ReadMe
* Support `analyzer: ">=8.1.0 <10.0.0"` (required since 0.1.0)

## 0.1.0

* Initial Release
* Depends on `build: ">=3.0.0 <5.0.0"`, `analyzer: ^8.0.0`, `build_runner: ^2.0.0` and `build_config: ^1.0.0`
