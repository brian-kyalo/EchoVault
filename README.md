
# EchoVault

**My thoughts belong to me.**

EchoVault is a privacy-first, local-first journal and spelling-practice app
being built incrementally as a Flutter/BLoC learning project.

## Current status: session journal preview

Implemented:

- Separate startup, application widget, and branding configuration.
- Centralized dark theme with soft-neon accents and readable typography.
- Scrollable welcome screen and working build-information dialog.
- Journal list and editor with create, edit, delete, validation, and discard confirmations.
- Explicit BLoC events and immutable states backed by an in-memory repository.
- Centralized routes and tests for journal operations, failures, and accessible layouts.

**Session only:** entries disappear when the app process restarts, including hot
restart. Hot reload normally preserves the running session. Encryption is not
active. Use sample writing only.

**Not implemented yet:** encryption, database, app lock, persistent onboarding,
spelling correction, learning records, games, statistics, speech recognition,
and settings.

## Privacy direction

The intended product will encrypt journal content before local persistence,
require no account, and use neither analytics nor remote AI APIs. Learning data
will contain accepted word pairs only, never journal context or entry IDs.
These are requirements for later milestones, not security guarantees of this
preview. No persistent storage or networking service is implemented.

## Setup and run

The foundation was analyzed and tested on Windows using Flutter **3.44.7 stable**
and Dart **3.12.2**. Android and iOS platform projects are present. iOS builds
require macOS and Xcode; web and desktop are not configured as product targets.

1. Install Flutter and the Android SDK; check `flutter doctor -v`.
2. Start an Android emulator or connect a USB-debugging-enabled Android phone.
3. Run `flutter pub get` in the project root.
4. Check `flutter devices`, then run `flutter run -d <device-id>`.

The foundation was successfully launched on the user's Android emulator.
Use Flutter's **Run > Start Debugging (F5)** in VS Code, not Code Runner's
**Run Code** command. After adding dependencies, stop and restart the debug run.

## Checks

- `flutter analyze` — static analysis.
- `flutter test` — BLoC/repository and widget tests.

## Contributing

Work is tracked with [GitHub issues](https://github.com/brian-kyalo/EchoVault/issues)
and [milestones](https://github.com/brian-kyalo/EchoVault/milestones). Changes use
issue-linked Conventional Commits and focused pull requests into `main`.
See [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming, commit examples,
verification commands, and privacy requirements. GitHub Actions checks
formatting, analysis, tests, and pull request conventions.

## Dependencies

Flutter provides the UI, `flutter_bloc` connects explicit events and states to
widgets, and `bloc_concurrency` serializes repository operations. `flutter_test`
provides testing and `flutter_lints` supplies analysis rules. Persistence
dependencies will be selected when encrypted storage is introduced.

See [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md).

## Learning and architecture

- [Architecture](docs/ARCHITECTURE.md)
- [Project map](docs/PROJECT_MAP.md)
- [Learning path](docs/LEARNING_PATH.md)
- [Storage design proposal](docs/STORAGE_DESIGN.md)

## Renaming

Change the shared display name in [lib/app/app_identity.dart](lib/app/app_identity.dart),
the Android label in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml),
and the iOS display name in [ios/Runner/Info.plist](ios/Runner/Info.plist).
Native launcher labels cannot read a Dart constant. The Dart package name and
native application identifiers are separate from display branding. The native
identifiers still use the starter project's development defaults.

## Screenshots

Screenshots will be added after an Android device run has been verified.

## Next milestones

1. Review the session journal and its BLoC flow together.
2. Add tested encryption, key protection, and local database infrastructure.
3. Replace the in-memory repository with encrypted persistent storage.
4. Add remaining journal, privacy, spelling, game, and offline speech features.

The full product definition of done remains outstanding.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
