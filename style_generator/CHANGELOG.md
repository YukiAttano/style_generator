## 0.3.0

* Add quotation marks for String types in toString method
* Add explicit 'null' text for null value in toString method

## 0.3.0-dev

* *Breaking* CopyWith annotations applies the suffix 'Cw' by default now
* Add ToString and ToStringKey annotations

## 0.2.12

* Fix an issue, where the use of lists in classes generated wrong equality methods

## 0.2.11

* Fix an issue, where annotation keys (CopyWithKey, StyleKey, EqualityKey) were not found when used on fields, when the constructor parameter and the mapped field had different types

## 0.2.10

* Added CopyWithKey.unmodifiable, which prevents overriding fields. Useful for ID/UUID fields.

## 0.2.9

* Fix breaking code generation when private fields are assigned via constructor initializer list
* Fix weird behavior when a single constructor parameter is used to initialize multiple fields
* Added the CopyWithKey.field property constructor parameter, to allow setting the correct field if the auto-guessed field is wrong
* Fix spamming the console with unused type checks

## 0.2.8

* Support `analyzer: ">=10.0.0 <13.0.0"`

## 0.2.7

* Fix wrong 'missing import' warnings when multiple imports were defined
* Fix an error, where no class field were found when multiple generic ancestors are used

## 0.2.6

* Fix typo in README.md and add full `build.yaml` example

## 0.2.5

* Add `@override` annotation to `hashCode` and `operator ==` methods

## 0.2.4

* Fix crash on members using 'dynamic' as type argument (e.g. `List<dynamic>`, `Map<dynamic, dynamic>`)
* Add Equality and EqualityKey annotation

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

* Add IntelliJ/Android Studio plugin to README
* Support `analyzer: ">=8.1.0 <10.0.0"` (required since 0.1.0)

## 0.1.0

* Initial Release
* Depends on `build: ">=3.0.0 <5.0.0"`, `analyzer: ^8.0.0`, `build_runner: ^2.0.0` and `build_config: ^1.0.0`
