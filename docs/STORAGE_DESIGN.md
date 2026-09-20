# Device-only encrypted storage design

Tracking: [issue #3](https://github.com/brian-kyalo/EchoVault/issues/3).
Status: design under review. Crypto/key services are implemented separately
under issue #4 but are not connected to the journal; SQLite is not installed.
The owner agreed to a device-only learning milestone with recovery deferred.
Use sample writing until recovery and security behavior have been verified.

## Decision and scope

Keep JournalRepository as the storage boundary. Replace the in-memory
implementation only after encryption and key lifecycle tests exist.
Encrypt entry payloads before passing them to SQLite. Do not introduce
plaintext persistence, remote services, accounts, or analytics.

The proposed flow is:

```text
Editor -> BLoC -> JournalRepository -> encrypt -> SQLite transaction
List   <- BLoC <- JournalRepository <- decrypt <- SQLite query
                              |
                  key from OS-backed secure storage
```

SQLite provides persistence and atomic transactions, not encryption by itself.
Authenticated encryption provides confidentiality and detects modified payloads.
Secure storage protects the key at rest. An app lock is a separate future feature.

## Threat model

Protect titles, bodies, and entry timestamps in a copied database when the
attacker does not have the key or control of the running application.
Detect changed ciphertext, wrong keys, and substitution across entry IDs.

Not protected: an unlocked app, screenshots, keyboards, compromised/rooted
devices, a debugger, process memory, or an attacker able to use the app's key.
The application needs plaintext and key material in memory while operating;
do not claim guaranteed memory erasure in Dart or hardware isolation of that key.
This design does not detect deletion of rows, rollback of the whole database,
or replay of an earlier valid ciphertext for the same entry. It is not an audit.

## Library selection

Package documentation reviewed on 2026-09-20:

| Library | Version reviewed | License | Intended role |
| --- | --- | --- | --- |
| cryptography | 2.9.0 | Apache-2.0 | AES-256-GCM, secure key and nonce generation |
| flutter_secure_storage | 11.2.0 | BSD-3-Clause | Android protected storage and iOS Keychain |
| sqflite | 2.4.4 | BSD-2-Clause | Android/iOS SQLite transactions and schema versioning |

The crypto and secure-storage versions above now resolve with Flutter 3.44.7 /
Dart 3.12.2; sqflite remains a design selection, not an installed dependency.
Review native builds and upstream security advisories before production use.
The resolved secure-storage 11.x changelog requires Android API 24 or later,
despite the package overview still describing API 23 support.
Native iOS deployment requirements and entitlements need verification on macOS.

Choose sqflite over Drift for this small repository: no generated query layer
is needed yet. Choose encrypted payloads over a full SQLCipher database to keep
the cryptographic boundary independently testable. This deliberately exposes
structural metadata and prevents SQL searching/sorting of encrypted fields.
Consider cryptography_flutter only if native acceleration is justified and
its backend behavior is tested; cryptography alone must not be described as
automatically using Android/iOS hardware-backed cryptography.

## Payload and database format

Use one encrypted JSON payload per entry containing title, body, createdAt,
and updatedAt. Encode timestamps as UTC values; convert for display on load.
Retain the existing JournalEntry and JournalRepository public contracts.

Each row contains a random opaque entry ID, format version, 12-byte nonce,
ciphertext, and 16-byte authentication tag. Generate new IDs using secure
randomness, not the current session counter. Maintain a separate SQLite schema
version and a vault header with vault ID, key reference, and an authenticated
known-value check so a wrong key is detectable even for an empty journal.

Use AES-256-GCM through the library. Generate a fresh secure random nonce for
every encryption, including edits; never derive it from time or an entry ID.
Random generation makes collision unlikely, not impossible. Before production,
define key-usage limits/rotation; the sample-only milestone must not claim
unlimited safe encryption under one key. Do not reuse deterministic test RNGs
in application code.

Authenticate the application domain, vault ID, payload kind, format version,
and row ID as additional authenticated data using a fixed, unambiguous encoding
(for example a UTF-8 JSON array of strings and an integer version).
Use a distinct payload kind for the vault-header check. Reject unknown versions,
invalid lengths, authentication failure, and malformed decrypted JSON.

SQLite contains no plaintext titles, bodies, or entry timestamps, including in
indexes, temporary tables, WAL files, or rollback journals. It still reveals
the schema, opaque IDs, row count, ciphertext lengths, file size and filesystem
activity. Sorting requires decrypting entries in memory; retain the current
newest-updated ordering. Pagination and encrypted search are out of scope.

## Key lifecycle and startup

Generate a random 256-bit vault key with the cryptographic library. Store only
that small secret in secure storage under an app-specific, versioned key name.
Never put it in source code, SQLite, ordinary preferences, logs, or crash reports.
Base64 may encode the key for the secure-storage API; it is not encryption.

Bootstrap must initialize Flutter bindings before native plugins, prepare the
key and database, then inject the repository before showing journal content.
Startup failure must show a non-sensitive retry/error view, not silently fall
back to an empty in-memory journal. Keep unit tests injectable without plugins.

| Observed startup state | Required behavior |
| --- | --- |
| No vault and no key | Create key, verify secure-storage readback, then initialize the vault transactionally |
| Key exists but no vault | Verify the app-owned key and initialize a new empty vault; covers interrupted first setup or an iOS key surviving uninstall; never promise recovery |
| Vault and key exist | Verify header and format before allowing entry access |
| Vault exists but key is missing | Stop; preserve the database; do not generate a replacement key |
| Key cannot be read or header is invalid | Stop with a retry/error state; do not delete, overwrite, or reset anything |

Database and secure storage do not share a transaction. Key-first initialization
and the authenticated header must be tested with interruption at each boundary.
An incomplete/unknown existing vault is an error, not evidence of a new install.
Any destructive reset needs a separate explicit confirmation flow; it is not
an automatic error-handling path or part of this implementation scope.

## Platform backup and recovery policy

There is no password, recovery key, export, cloud backup, or device transfer
feature in this milestone. Loss of the device, database, or key may permanently
lose entries. Uninstall/reinstall is not a recovery strategy; iOS Keychain items
can outlive the app, while the app database may be removed.

On Android use the plugin's maintained default cipher choices, with
`resetOnError: false`, `migrateWithBackup: true`, and a stable dedicated namespace.
The default reset-on-error behavior is destructive and must not be enabled.
Migration backup here means local encrypted plugin copies, not a recovery or
cloud-backup feature. Do not use deprecated encryptedSharedPreferences options.
Disable backup and explicitly exclude vault data and secure-storage preferences
from applicable legacy backup and Android 12+ cloud/device-transfer rules.
Do not assume allowBackup=false alone prevents every manufacturer's transfer.
Verify the merged manifest and supported-device behavior before claiming this.
Review cross-platform transfer rules on newer Android releases as well; do not
enable an export/import path implicitly through platform defaults.

On iOS choose a non-synchronizing, when-unlocked, this-device-only Keychain
accessibility setting supported by the resolved plugin. Put the vault in private
application storage, not a user-visible Documents export, and exclude its
directory and SQLite sidecars from backup. Verify required native integration,
file protection, entitlements, and backup behavior on macOS/iOS. Do not claim
iOS parity from an Android test. No biometric/app-lock prompt is added here.
Apple cautions that backup exclusion is intended for support/cache resources
and can be reset by operations on user documents. Verify exclusion after vault
creation, replacement, and migration; review the user-data backup policy before
an iOS release. Merely setting an attribute is not sufficient validation.

These are implementation requirements, not guarantees about the current app.
Before real personal use, add and verify recoverable encrypted backup with a
separately protected recovery secret under a new reviewed design.

## Writes, failures, and migration

Encrypt before starting a database write. Use parameterized SQL and transactions;
publish success only after commit. Preserve IDs and creation times on edit.
Editing a missing ID must fail, not recreate a deleted entry. Serialize operations
and keep the current BLoC failure/draft-preservation behavior.

On corrupt entries, fail the load explicitly rather than silently omitting rows
or returning an empty list. Keep files intact and avoid including private data
in errors. A retry may help transient failures, not repair an invalid key.

Schema upgrades must be transactional and tested; reject unsupported newer
versions rather than downgrade or delete. Do not automatically persist the
existing session preview's contents. Deleting a row is logical deletion, not
guaranteed forensic erasure of flash storage or historical encrypted pages.

## Verification and delivery

The initial issue #4 implementation includes a versioned byte envelope,
context-bound AES-GCM, serialized key loading with write/readback verification,
and a native secure-storage adapter. It does not initialize a vault or use the
adapter at app startup. Use exactly one key-service instance per vault in the
future bootstrap; its queue coordinates that instance, not multiple isolates
or independent service objects. Only pass `vaultExists: false` after establishing
that no database/header/sidecars exist; unreadable or incomplete storage is not
an absent vault. Header validation and JSON payload validation belong to the
repository implementation, not the byte cipher.

Unit tests cover library known-answer data, envelope authentication/validation,
key service failure paths, and adapter option serialization. These tests do not
prove Android Keystore/iOS Keychain durability, native error behavior, backup
exclusion, interrupted database creation, or real-device restart recovery.
Issue #4 remains open for native integration evidence and outstanding key-lifecycle
checks; issues #5/#6 cover repository and broader persistence verification.

- Issue #4: crypto known-answer/round-trip tests, Unicode, wrong keys, nonce/tag/
  ciphertext/AAD tampering, malformed envelopes, and version rejection. Test
  nonce generation wiring without claiming a finite test proves uniqueness.
- Issue #4: key persistence, secure-storage failure, key readback failure, no key
  regeneration for an existing vault, and each interrupted-startup state.
- Issue #5: repository CRUD/reopen tests, creation timestamps, ordering, missing
  IDs, rollback on write failure, unsupported schemas, corrupt header/entry,
  and preserved editor drafts. Inject storage fakes for fast unit tests.
- Issue #6: real SQLite and plugin integration tests on Android, including full
  process restart. Unit mocks are not evidence that secure storage works.
- Issue #6: scan database/sidecars/logs for synthetic plaintext markers, and
  verify backup exclusions and key-loss behavior. Record Android API/device
  coverage; list iOS as unverified until its native tests can run.
- All implementation PRs: formatting, analysis, existing widget/BLoC tests,
  focused new tests, and honest UI warnings. No security or recovery badge.

## Sources

- [cryptography documentation](https://pub.dev/packages/cryptography)
- [flutter_secure_storage documentation](https://pub.dev/packages/flutter_secure_storage)
- [sqflite documentation](https://pub.dev/packages/sqflite)
- [Android backup guidance](https://developer.android.com/identity/data/autobackup)
- [Apple device-only Keychain accessibility](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly)
- [Apple backup exclusion](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup)