# Firebase development setup

Use a separate Firebase project that you own. The checked-in `lib/firebase_options.dart`, `android/app/google-services.json` and FlutterFire metadata describe the original project's client configuration; they are not service-account credentials or a backend export.

## Configure the services

1. Create/select your development project in the Firebase console.
2. Enable **Authentication → Email/Password**.
3. Create a **Cloud Firestore** database and a **Storage** bucket. Review current Firebase billing requirements before enabling services.
4. Register the platform apps you intend to run. Android currently uses `com.example.brotrachka`; match that application ID when configuring it.
5. Generate client configuration with the official [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup). If using the pinned Dart 3.5 toolchain, use a compatible CLI release, rather than assuming the latest CLI supports it. The CLI authentication/configuration step was not executed during the portfolio review.

```bash
# After installing and authenticating the Firebase and FlutterFire CLIs:
flutterfire configure --project=<your-project-id> --platforms=android,web
```

Inspect the generated configuration diff. Do not add service-account JSON, private keys or account passwords to the repository. iOS requires its own platform configuration and macOS/Xcode to build.

## Data layout expected by the client

| Path | Purpose |
| --- | --- |
| `users/{uid}` | Display name, email, role, city, rating and profile image URL |
| `nicknames/nicks` | Document with a `nicknames` array; initialize it to `[]` in an empty development database |
| `jobs/{jobId}` | Listing details, employer ID, `createdAt`, required/accepted headcount |
| `jobs/{jobId}/applications/{uid}` | Employer-facing application status |
| `users/{uid}/applications/{jobId}` | Worker-facing application status |
| `chats/{chatId}/messages/{messageId}` | Messages, sender/receiver IDs, timestamps and read state |
| `reviews/{reviewId}` | Reviewer, recipient, job, rating and comment |
| `friendships/{requestId}` and `users/{uid}/friends/{friendId}` | Friend requests and accepted contacts |
| Storage: `users/{uid}/profile_images/...` | Uploaded profile images |

Create the nickname document only in your development database. Other documents are normally created by application flows. Do not seed invented production users or results for portfolio screenshots.

## Rules and indexes

The repository does **not** include Firestore rules, Storage rules or an index export. A frontend build cannot verify the original project's deployed rules.

Before using real data, define and test rules for authenticated identity, ownership of listings and profiles, application transitions, participant-only chat access, reviews and image uploads. The nickname lookup currently happens before account creation; account for this deliberately without granting public writes. Do not use unrestricted `allow read, write: if true` rules as a setup shortcut.

Firestore may request composite indexes for compound friendship/message queries. Follow the exact index link reported by your development project, then export reviewed configuration for future reproducibility.

Firebase client API keys are normally public identifiers used by client SDKs. Restrict their allowed APIs/applications where appropriate and verify backend rules. Their presence alone does not prove either a credential leak or a secure backend. Never publish Admin SDK credentials.

## Manual verification

With two accounts under your control, check registration/login, role selection, listing creation, application acceptance/rejection, messaging, and reviews. Use a private development dataset. Record which flows actually succeeded and any errors; the local tests in this repository do not replace these checks.
