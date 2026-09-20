# Contributing to EchoVault

EchoVault is a Flutter/BLoC learning project. Keep each change small enough to
explain, test, and review. Use sample journal content only in code, screenshots,
issues, logs, and pull requests. Never publish personal writing or credentials.

## Issue to pull request

1. Open an issue describing the problem, scope, and acceptance criteria.
2. Assign the issue to a milestone representing a usable outcome.
3. Start from an up-to-date `main` and create a branch such as
   `feat/12-encrypted-storage`, `fix/18-editor-back`, or `chore/2-repo-workflow`.
   The number is the actual GitHub issue number, not an invented placeholder.
4. Make focused commits using the format below. Run the checks before pushing.
5. Open a pull request into `main` and complete the PR template. Put
   `Closes #12` in its description only when all acceptance criteria are met.
   Use `Refs #12` for partial work so merging does not close the issue early.
6. Review the diff and checks, then squash merge. The final commit must retain
   its Conventional Commit title and issue reference. Delete the merged branch.

The initial snapshot on `main` is the bootstrap exception: it gives later PRs
a base to compare against. Do not invent historical commits for existing work.
After bootstrap, all changes should go through a PR. For a solo maintainer,
review the diff yourself; a required approval from yourself is not possible.

## Commit messages

Use `type(scope): short imperative description`, with an optional scope.
Keep titles specific; explain why in the body when it is not obvious.

```text
feat(journal): persist encrypted entries

Replace session-only storage while keeping the repository contract stable.

Refs #12
```

Common types:

| Type | Use |
| --- | --- |
| `feat` | New user-facing behavior |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `test` | Test additions or changes |
| `refactor` | Internal changes without changing behavior |
| `ci` | CI configuration |
| `chore` | Tooling, maintenance, or repository setup |

Reference a real issue in every project commit, including documentation and
maintenance work. Prefer `Refs #12` in intermediate commits and `Closes #12`
in the completed PR. Do not use the same issue to bundle unrelated work.
PR titles use the same Conventional Commit format as commit titles.

## Checks

Use Flutter 3.44.7 stable, matching the version pinned in CI.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

If formatting fails, run `dart format lib test`, inspect the changes, and rerun
the checks. Commit `pubspec.lock` because EchoVault is an application. When
intentionally changing dependencies, update the lockfile with `flutter pub get`.

CI runs formatting, analysis, and tests on PRs and pushes to `main`. It also
checks PR titles and issue references. It does not prove that Android/iOS builds
work, that the UI looks correct on a device, or that encryption is secure.
Describe manual device verification and any unverified requirements in the PR.

## Review boundaries

- Keep UI, BLoC orchestration, and repository/storage responsibilities separate.
- Include a regression test for a bug fix and focused tests for new behavior.
- Do not introduce plaintext journal persistence as a temporary shortcut.
- Discuss encryption, key recovery, and backup behavior before implementing them.
- Never commit signing keys, local SDK paths, real journal exports, or secrets.
- Do not report security vulnerabilities in public issues. Use GitHub private
  vulnerability reporting when enabled, or arrange a private channel first.

Milestones describe outcomes, not delivery-date promises. Close a milestone only
when its acceptance criteria and linked issues are complete. A passing test suite
does not make a preview production-ready.