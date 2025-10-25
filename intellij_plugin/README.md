<!-- HOW TO -->
This Section is for the sad guy who has to deal with this bullshit.
Imagine you want to share a single XML file and you have to setup a Gradle project.
To increase the fun, all documentations are somewhat crap.

The important files:
* `src/main/resources/META-INF/plugin.xml` defines where to find the Live Templates
* `src/main/resources/templates/StyleGenerator.xml` is the delivered Live Template. More templates must be spit into this folder and defined in the plugin.xml
* `gradle/libs.version.toml` some random dependency definitions. The file is purely used as a lookup table
* `build.gradle.kts` Everything that happens, happens here
* `build/distributions` The exported file after `./gradlew buildPlugin`

Some useful Links:
* [Original Plugin Template](https://github.com/JetBrains/intellij-platform-plugin-template) The Template on which this is build
* [intellij plugin dependency](https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin-dependencies-extension.html) Explains how the base IDE can be chosen

Some commands:
* `./gradlew clean build --refresh-dependencies` 
* `./gradlew tasks --all` list all tasks like clean, build and run
* `./gradlew wrapper` does something
* `./gradlew runIde` start project in a new IDE with defined dependencies
* `./gradlew buildPlugin` build the plugin, must potentially be signed after that

<!-- HOW TO END -->

# Style Generator Templates for Flutter

<!-- Plugin description -->
**Style Generator Templates for Flutter**
The main goal of this template is to speed up the setup phase for your styles.
See [style_generator on pub.dev](https://pub.dev/packages/style_generator)

The following templates are provided:

* styfile - Generates a ready to use Style with imports
* styclass - Generates an empty Style class without imports
* style - Generates a ready to use Style class
* stypart - Generates the Style part file
* styof - Generates the Style of Constructor

<!-- Plugin description end -->

See [style_generator on pub.dev](https://pub.dev/packages/style_generator)

