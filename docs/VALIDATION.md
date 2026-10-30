# Technical review and validation

Reviewed against original commit `6394417` and the portfolio changes, using Flutter 3.24.5 / Dart 3.5.4 on Linux. The original history has two commits; `master` is the source branch. No history or branches were deleted.

## Checks actually executed

| Check | Result | What it establishes |
| --- | --- | --- |
| `flutter pub get --enforce-lockfile` | Passed; lock file unchanged | The committed dependency set resolves with the selected SDK |
| Original counter widget test | Failed: Firebase `[core/no-app]`, then missing counter text | The starter test did not represent this application |
| Current `flutter test --no-pub --concurrency=2` | **4 tests passed** | Job date deserialization/round-trip and job-card rendering/tap behaviour |
| `flutter analyze --no-pub` | Exit 1; **531 info diagnostics, 0 warnings, 0 errors** | Source analysis completed; lint debt remains |
| `flutter build web --no-pub` | Passed | The client compiles for web |
| Local static serving / browser attempt | HTML served; Flutter renderer/font CDN access blocked | Does not validate registration or authenticated workflows |
| Android/iOS release builds | Not run | No native-release readiness claim |
| Firebase-backed scenarios | Not run | No claim that deployed rules, indexes or end-to-end flows work |

The first analyzer attempt failed because the cloud sandbox prevented writing its cache; it was rerun successfully with the required filesystem access. CI reports info diagnostics with `--no-fatal-infos`; warnings/errors, test failures and build failures still fail the workflow. A new GitHub Actions run has not been observed as part of this local review.

## Changes with a functional effect

`JobService.createJob` writes `createdAt`, but `Job.fromMap` previously read only `postedAt`, replacing persisted creation dates with the current time. Deserialization now accepts `createdAt`, legacy `postedAt`, and a local `DateTime` from `toMap`. Regression tests cover these cases.

The obsolete counter test was replaced by a real job-card interaction test; it is not presented as an end-to-end application test. The original failing test was executed separately before recording the replacement's results.

The Xcode workflow invoked Xcode at the repository root without installing Flutter or resolving its packages. It now runs locked dependency resolution, analysis, local tests and web compilation on Linux. The existing workflow file was retained.

## Confirmed source limitations

- Nickname registration reads a shared array, then calls `update` on `nicknames/nicks`. An empty database requires that document to be initialized. This is not an atomic uniqueness constraint.
- User creation, profile creation and nickname updates can partially succeed; errors are caught and represented as a null registration result.
- Applications are duplicated under users and jobs through separate writes. Acceptance uses an increment outside the capacity-checking service transaction, so concurrent decisions need further work.
- The profile tab reads `late` fields before asynchronous loading has necessarily finished. Editing a name writes `name` while other screens read `displayName`; avatar field names also differ.
- Job conversations reuse an ordered participant-based ID. This can associate several jobs with one conversation; reverse participant ordering can create another conversation.
- Deleting a chat document does not explicitly delete its messages. Review/rating updates are separate operations.
- Image upload uses `dart:io`/`putFile`; browser compatibility needs a targeted change and test.
- Firebase rules, Storage rules and a composite-index export are absent. Client-side role controls do not establish server-side authorization.

These findings were not expanded into a broad application refactor.

## Credential review

A pattern scan covered 125 text blobs reachable from the fetched Brotrachka branches. It found Firebase client API keys in generated client configuration. No matching private key, GitHub token or Telegram bot token was found by those patterns. This is a limited scan, not proof that every possible credential pattern is absent.

Firebase client configuration is expected in client applications; no Admin SDK/private credential was identified. Backend security cannot be inferred from these files. Review API restrictions and deployed Firebase rules in the project console. The review did not alter the Firebase project, its data or access settings.

## Visual evidence still needed

See [SCREENSHOTS.md](SCREENSHOTS.md). Browser access to `www.gstatic.com` and `fonts.gstatic.com` was denied by the cloud network policy. No screenshots were manufactured, and no public deployment was created.
