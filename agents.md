# AI Agent Instructions: Mentor Contract & Payment Tracker

## 1. Project Overview
You are building a mobile application for a mentor/course creator to manage programs, generate and sign contracts, and track student payments. 
**Core constraint:** The entire tech stack must remain 100% free of charge. Do not suggest or implement any paid third-party APIs, SaaS products, or backend services outside of the approved stack.

## 2. Tech Stack
*   **Frontend / Mobile Framework:** Flutter (Dart). Target platforms: Android and iOS.
*   **Backend / Database:** Supabase (PostgreSQL, Auth, Storage).
*   **State Management:** Riverpod (using `riverpod_annotation` and code generation).
*   **Routing:** `go_router`.
*   **Key Flutter Packages:**
    *   `supabase_flutter`: Database, storage, and backend logic.
    *   `pdf` & `printing`: Generating the contract PDFs natively on the device.
    *   `signature`: Capturing on-screen signatures.
    *   `path_provider`: Local file saving before uploading to Supabase.

## 3. Architecture Guidelines
Implement a **Feature-First (Domain-Driven) Architecture**. Do not use layer-first (e.g., grouping all UI together and all controllers together). The `lib/` folder should be structured as follows:

*   **`lib/core/`**: App-wide constants, themes, routing configurations, and Supabase client initialization.
*   **`lib/features/`**: Grouped by domain (e.g., `programs`, `students`, `contracts`, `payments`).
    *   Each feature folder must contain:
        *   `/models`: Data classes (`freezed` or standard Dart data classes with `fromJson`/`toJson`).
        *   `/repositories`: Classes handling direct Supabase queries.
        *   `/controllers`: Riverpod providers managing state and business logic.
        *   `/views`: Flutter widgets and screens specific to the feature.

## 4. Backend Rules (Supabase)
*   **Database Interactions:** All data fetching and writing must be done via the `supabase_flutter` client. 
*   **Relational Logic:** Use PostgreSQL joins (via Supabase's `select('*, table(*)')` syntax) to fetch nested data, such as a Program with all its Students, or an Enrollment with all its Payments.
*   **PDF Storage:** Generated PDFs must be uploaded to a public Supabase Storage bucket named `contracts`. Save the returned public URL to the `contracts` database table.

## 5. CI/CD & Automated GitHub Releases
You are responsible for generating the GitHub Actions workflows to automate releases.

*   **Workflow File Location:** `.github/workflows/release.yml`
*   **Trigger:** The workflow should trigger automatically when a new version tag is pushed (e.g., `v1.0.0`).
*   **Jobs Required:**
    1.  **Setup & Test:** Check out the repository, install the Flutter SDK (using `subosito/flutter-action`), get dependencies, and run tests.
    2.  **Build APK (Android):** Run `flutter build apk --release`.
    3.  **Build App Bundle (Android):** Run `flutter build appbundle --release`.
    4.  **Create GitHub Release:** Use `softprops/action-gh-release` to automatically create a new Release on the GitHub repository and upload the `.apk` and `.aab` artifacts to it.
*   *Note for iOS:* Due to Apple's strict code-signing requirements, exclude iOS from the automated GitHub release artifacts unless explicitly provided with a signing certificate and provisioning profile in the repository secrets. Stick to Android artifacts for the zero-cost automated pipeline.

## 6. Coding Standards & Agent Behaviors
*   **Null Safety:** Strictly enforce Dart null safety. Never use the `!` operator to force unwrap a nullable variable unless mathematically proven to be non-null in the preceding line.
*   **Error Handling:** Wrap all Supabase calls in `try-catch` blocks. Surface errors to the UI using a standard `SnackBar` or error banner, never silently fail.
*   **UI/UX:** Use Material 3 design guidelines (`useMaterial3: true`). Keep the interface clean, heavily utilizing `Card`, `ListTile`, and `DataTable` widgets to display the relational data clearly.
*   **Step-by-Step Execution:** When asked to build a feature, write the Model first, the Repository second, the Controller third, and the UI last. Do not attempt to write the entire feature in a single file or a single step.

## 7. Mandatory Approval & Workflow Protocol (STRICT GUARDRAIL)
*   **Answer & Present Proposal First:** Whenever the user asks a question, requests a feature, or discusses options, the agent MUST first thoroughly research, analyze, and present the technical proposal and options to the user for discussion.
*   **Explicit Approval Required Before Code Changes:** The agent MUST ALWAYS stop and wait for explicit user approval before writing code, editing files, making commits, or running state-changing commands.
*   **No Premature Autonomous Execution:** NEVER jump straight to modifying files or implementing features until the user explicitly responds with approval to proceed with a specific proposed plan.