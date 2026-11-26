# Java (and other JVM languages)

Maven (`mvn`) or Gradle (`gradle` / `./gradlew`): use the project's wrapper (`./mvnw`, `./gradlew`) when it exists. Below, the default when the project defines nothing; the plugins only apply if they are configured in `pom.xml`/`build.gradle`.

## Static analysis and compilation

- Compile: `mvn -q compile` / `mvn -q test-compile`; `./gradlew compileJava compileTestJava`. "Compiles" includes the test code.
- Lint and analysis: Checkstyle, SpotBugs, PMD, Error Prone, as the project uses (`mvn checkstyle:check`, `./gradlew check`).
- `-Xlint:all` and `-Werror` show how much the compiler already reports.

## Formatting and automatic fixes

- Spotless or google-java-format: `mvn spotless:apply`, `./gradlew spotlessApply`; without a plugin, the IDE formatter with the project's `.editorconfig`/style.
- Suggested post-edit order: automatic fix/format → compile → analysis → tests.

## Checking without changing files

For a review, which never writes: `mvn spotless:check` / `./gradlew spotlessCheck`, `mvn -q verify` / `./gradlew check` (writes only to `target/` and `build/`, which are not versioned) and the tests. Never `spotless:apply` nor a formatter that writes, and nothing that updates dependencies or the lockfile.

## Tests and coverage

- JUnit 5 (sometimes TestNG): `mvn test`, `./gradlew test`. A single test: `mvn -Dtest=NameTest#method test`, `./gradlew test --tests 'package.NameTest.method'`.
- How to write: `write-dart-tests` (general rules).
- Tests mirror `src/main/java` in `src/test/java`, with the `Test` suffix. Categories: `@Tag("slow")`.
- Coverage: JaCoCo (`mvn verify` with the plugin, report in `target/site/jacoco`; `./gradlew jacocoTestReport`).
- Async: `CompletableFuture` with `get(timeout)` or Awaitility; never `Thread.sleep` to wait.
- Exception: `assertThrows(Type.class, () -> ...)` and then check the message and the state.
- `git stash push -- <production files>` serves for the red → green proof.

## Manifest, lockfile and dependencies

- `pom.xml`, or `build.gradle`/`build.gradle.kts` with `settings.gradle`. Maven has no lockfile; Gradle only has one if the dependencies are locked (`gradle.lockfile`) or it uses `libs.versions.toml`.
- The versions or lock file goes with the manifest change in the same commit.

## Generated files

- `target/` and `build/` (not versioned), `build/generated`, `target/generated-sources`, annotation processor output (Lombok, MapStruct, Dagger, Immutables), generated protobuf/OpenAPI/jOOQ code.
- Regeneration: through the build (`mvn generate-sources`, `./gradlew generateProto`, …), never by editing the result.
- It stays out of coverage (JaCoCo exclusions) and of style inference.

## Doc comments, references and TODO

- Javadoc `/** ... */`; symbol reference `{@link Class#member}`, `{@link Class}`; `@param name`, `@return`, `@throws Type`. The first sentence is the summary.
- `// TODO(name): ...`.

## Suppressing a lint or a type error

- `@SuppressWarnings("unchecked")` (the smallest possible scope), `// CHECKSTYLE:OFF`/`ON`, `@SuppressFBWarnings`.

## Nulls

- No null safety in the language: `@Nullable`/`@NonNull` (JSpecify, JetBrains, Checker Framework), `Optional<T>` only for return values, `Objects.requireNonNull(x, "reason")` to fail early.
- In Kotlin (JVM), `?` and `!!` play the role of Dart's `?` and `!`.

## Script output

- `System.out.print("text ... "); System.out.flush();` before slow work; errors on `System.err`.
- Child process: `new ProcessBuilder(...).inheritIO().start()` instead of reading and reprinting the output.

## Post-edit flow

There is no dedicated skill. Run, in this order: formatting, compilation (including tests), static analysis, the module's tests and then the full suite, through the project's wrapper.
