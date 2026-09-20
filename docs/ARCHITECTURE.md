# Architecture: session journal milestone

## What exists today

The structure is feature-first without empty layers or speculative interfaces.

- `app`: startup, root application widget, and branding.
- `core/theme`: visual decisions shared by features.
- `features/onboarding`: the welcome view and its focused presentation widgets.
- `features/journal`: immutable entries, repository contract, BLoC, list, and editor.

Startup follows this actual path:

1. [main.dart](../lib/main.dart) calls `bootstrap()`.
2. [bootstrap.dart](../lib/app/bootstrap.dart) mounts `EchoVaultApp` with `runApp()`.
3. [app.dart](../lib/app/app.dart) creates a repository and BLoC through providers,
   dispatches `JournalLoadRequested`, and builds the themed `MaterialApp`.
4. [app_router.dart](../lib/app/app_router.dart) owns routes for the initial
   journal list, entry editor, and about/welcome screen. All share one BLoC.

Bootstrap is deliberately synchronous. No database or service needs initialization
yet. When those resources exist, this boundary will initialize and inject them
before sensitive UI can be shown; initialization must not happen in `build()`.

## A real interaction today

Tap **About this build** → `FilledButton.onPressed` →
`BuildInfoDialog.show(context)` → Flutter `showDialog<void>()` →
`BuildInfoDialog.build()` → visible `AlertDialog`.

Tap **Back to welcome** → `TextButton.onPressed` →
`Navigator.of(context).pop()` → dialog route closes → welcome remains visible.

This interaction is ephemeral presentation state owned by Flutter's Navigator.
It does not need a repository, stored setting, event, or BLoC. A widget callback
is appropriate here because it only opens/closes presentation UI.

## Journal state flow

The implemented flow is:

View -> explicit BLoC event -> sequential handler -> repository -> immutable
state -> BlocBuilder/BlocConsumer -> updated view.

`JournalLoadRequested`, `JournalSaveRequested`, and `JournalDeleteRequested`
share one sequential event queue, so operations cannot overtake each other.
The BLoC validates nonblank writing, emits busy/success/failure states, and
keeps the previous entry list on failure. Errors shown to users do not include
repository exception details or journal content.

`JournalRepository` is the storage boundary. `InMemoryJournalRepository` assigns
session IDs, preserves creation timestamps on edit, and returns newest-updated
entries first. Entries and state lists are immutable. It writes no files and
does not encrypt memory. Restarting the app creates an empty repository.

Widgets own text controllers, validation presentation, navigation, and temporary
confirmation dialogs. They do not own the entry collection. The editor stays
open with its draft on save failure; successful saves/deletes return to the list.
Back navigation checks unsaved changes, and deletion requires confirmation.
Busy operations disable editor actions. Providers own the BLoC lifecycle.

No Cubit, service locator, or additional routing package is used. The three
local routes use Flutter's Navigator through a centralized route factory.

## Next storage boundary

An encrypted repository will replace the session implementation after key
management, authenticated encryption, and database behavior have their own tests.
No plaintext persistence is introduced as an intermediate step. Resource
initialization belongs in bootstrap before the journal UI is mounted.

## Design and accessibility

Colors, typography, spacing, corner radii, and dialog duration are centralized.
Widgets obtain semantic colors from the theme. The welcome screen has a bounded
reading width but no fixed content height, and scrolls for smaller screens or
larger fonts. The information dialog also scrolls. The dialog transition checks
the platform's reduced-animation setting. Decorative icons do not duplicate
screen-reader descriptions. No fonts are fetched over the network.

## Scope honesty

There is no encrypted vault yet. Journal input is session-only and explicitly
marked as temporary and unencrypted. Onboarding is an informational about page,
not a persisted first-launch flow. Use sample writing only. No security badge
claims that storage is protected before that can be tested.