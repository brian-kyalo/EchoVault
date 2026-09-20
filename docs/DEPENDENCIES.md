# Dependencies: session journal milestone

## Version policy

Use the existing Flutter 3.44.7 stable / Dart 3.12.2 installation. Do not
upgrade the SDK merely because an update notice appears. Resolve packages
against this toolchain, inspect compatibility and licenses, and document the
reason for each addition. Commit the application lockfile when Git is initialized.

The BLoC packages resolved successfully against the existing SDK without an
SDK upgrade. Exact versions are recorded in the application lockfile.

| Dependency | Source / constraint | Why it exists | License |
| --- | --- | --- | --- |
| flutter | Flutter SDK | Widgets, Material UI, theme, navigation, accessibility | BSD-3-Clause |
| flutter_bloc | `^9.1.1` (resolved 9.1.1) | BLoC providers, builders, and listeners for the journal | MIT |
| bloc_concurrency | `^0.3.0` (resolved 0.3.0) | Sequential handling across load/save/delete events | MIT |
| flutter_test | Flutter SDK, development only | Render widgets and test user interactions without a device | BSD-3-Clause |
| flutter_lints | Existing starter constraint `^6.0.0`, development only | Shared Dart/Flutter analysis rules | BSD-3-Clause |

The current design uses Material icons bundled with Flutter. The static about
screen needs no BLoC. Journal application state uses `Bloc`, not `Cubit`.
`bloc` 9.2.1 is resolved transitively through these packages. Tests use the SDK's
existing `flutter_test` and stream assertions, with no extra mocking package.

Dependency resolution succeeded. Pub reported newer versions of
seven transitive packages outside the current constraints; that is not a build
failure and is not a reason to override SDK-compatible constraints.

Future additions include authenticated cryptography, secure storage,
SQLite/Drift, device authentication, and offline speech components.
These are candidates, not installed or verified dependencies. Stable versions,
platform requirements, maintenance, and licenses must be checked when selected.

The [device-only storage proposal](STORAGE_DESIGN.md) selects `cryptography`,
`flutter_secure_storage`, and `sqflite` for the next milestone, subject to
dependency resolution and native validation. Its reviewed versions and licenses
are recorded separately from the installed dependencies above.