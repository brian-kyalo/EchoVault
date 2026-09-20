# Learning path

We are reviewing small verified milestones before adding more complexity.
This is not the complete product or the final project tree.

## Review order

1. [pubspec.yaml](../pubspec.yaml): package configuration and dependencies.
2. [main.dart](../lib/main.dart) and [bootstrap.dart](../lib/app/bootstrap.dart): startup.
3. [app.dart](../lib/app/app.dart): root widget and MaterialApp.
4. [app_identity.dart](../lib/app/app_identity.dart): branding constants.
5. [app_tokens.dart](../lib/core/theme/app_tokens.dart) and
   [app_theme.dart](../lib/core/theme/app_theme.dart): centralized styling.
6. [welcome_page.dart](../lib/features/onboarding/views/welcome_page.dart): widget composition.
7. [privacy_principle_card.dart](../lib/features/onboarding/widgets/privacy_principle_card.dart)
   and [build_info_dialog.dart](../lib/features/onboarding/widgets/build_info_dialog.dart):
   focused widgets and ephemeral interaction.
8. [widget_test.dart](../test/widget_test.dart): verifying behavior.

The next implemented flow to review is `journal_entry.dart` ->
`journal_repository.dart` -> `journal_bloc.dart` -> journal views, under
`lib/features/journal/`. Follow a `JournalSaveRequested` event from the editor
through the repository and back to a saved state. Database and encryption are
still future work. Do not move to the next major file
until you can explain the current one in your own words.

## First file lesson

### FILE

[pubspec.yaml](../pubspec.yaml)

### PURPOSE

Declares what the project is and what it needs to build. Think of it as the
project's manifest and ingredient list, not executable Dart code.

### WHY IT EXISTS

Flutter and Pub need one predictable place to find the package name, supported
Dart versions, dependencies, and bundled assets.

### WHO USES IT

Flutter tooling, the Pub dependency resolver, the analyzer, tests, and builds.
The UI does not execute this file at runtime.

### WHAT IT USES

YAML configuration, Flutter SDK packages, and packages resolved through Pub.
YAML indentation determines which values belong to which section.

### FLOW

`flutter pub get` reads the constraints and resolves dependencies into
[pubspec.lock](../pubspec.lock). Dart tooling can then locate imported packages.
Builds also use the Flutter configuration to bundle required resources.

### CODE WALKTHROUGH

- `name: echo_vault`: the Dart package identifier. Tests use imports such as
  `package:echo_vault/app/app.dart`. This is not the launcher display name.
- `description`: a short explanation of the intended product, not a feature guarantee.
- `publish_to: 'none'`: prevents accidental publication to the Dart package
  registry. It does not prevent Android or iOS app-store publication.
- `version: 1.0.0+1`: the starter's version and build number; this value does not
  mean the product is complete or release-ready.
- `environment` → `sdk: ^3.12.2`: accepts Dart from 3.12.2 inclusive up to, but
  not including, 4.0.0. This is a Dart constraint, not a Flutter version pin.
- `dependencies` → `flutter` → `sdk: flutter`: uses the Flutter SDK package
  supplied by the installed SDK rather than a hosted package version.
- `dev_dependencies`: development tools. `flutter_test` comes from the SDK;
  `flutter_lints: ^6.0.0` accepts compatible 6.x releases.
- `flutter` → `uses-material-design: true`: bundles the Material icon font used
  by the welcome screen. Material widgets themselves come from the SDK.
- Remaining starter comments demonstrate how assets/fonts could be declared;
  commented examples do not configure or download anything.

### IMPORTANT LINES

`sdk: ^3.12.2` specifies compatibility, whereas the lockfile records exact resolved
package versions. A constraint answers "what versions may be used?"; a lockfile
answers "which versions did this application resolve?"

### FLUTTER/DART CONCEPT

A package is a named unit of code/resources with a manifest. A dependency is
another package it uses. Development dependencies support testing and tooling;
they should not be imported by production application code.

### BLOC CONCEPT

`flutter_bloc` now connects journal widgets to explicit events and states.
`bloc_concurrency` provides the sequential transformer that keeps load, save,
and delete operations ordered. They are runtime dependencies because the
running application uses them, unlike `flutter_test`.

### WHAT WOULD BREAK IF REMOVED

Flutter would no longer recognize this directory as a valid Flutter package;
dependency resolution, normal builds, and tests would fail.

### EXPERIMENT

Rewrite only the `description` in your own words. Predict whether the welcome
screen changes. It should not: displayed branding comes from Dart constants,
not the manifest's description.

### QUESTION

1. Why can the launcher say "EchoVault" while this package is named `echo_vault`?
2. What is the difference between a dependency constraint and a locked version?
3. Why is `flutter_test` a development dependency rather than a runtime dependency?