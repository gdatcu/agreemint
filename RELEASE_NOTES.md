# 🚀 Agreemint v1.5.12 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **1-Tap ANAF CUI/CIF Live Auto-Lookup**: Instant company retrieval from Romania's official ANAF V9 registry, automatically filling company legal name, seat address, and Trade Register number.
* **Dual-Channel Outgoing Notifications (WhatsApp & Email)**: Direct deep-linking WhatsApp notifications and transactional Resend emails with personalized Romanian templates for contract signing, installment payment reminders, receipts, and student follow-ups.
* **Student Birthdays & Romanian Name Days (Onomastică)**: Automatic detection of student birthdays (derived deterministically from 13-digit Romanian CNP) and 14 Romanian Orthodox feast name days (including dynamic Floriile), with automated Discord notifications and 1-tap WhatsApp greetings.
* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **Prospect Follow-ups & Lead Pipeline CRM**: Lead tracking with top KPI metrics (Total Leads, Due/Overdue, Contacted, Converted & Conversion Rate %, Lost), live search, sorting, and 1-tap WhatsApp outreach.
* **1-Tap Mentorship Graduation Certificate Generator**: Official, branded QualiAdept Mentorship Completion Certificates with customizable course hours, sessions count, bilingual RO/EN translations, public verification portal, and PDF preview.
* **Live Search & Multi-Filter Roster**: Real-time instant search by Student Name, Email, Phone, and CUI/CIF, with multi-status filter chips.
* **Custom Contract & Business Settings Screen**: Configure company details, default contract terms, Resend API keys, and default mentor signature PNG directly inside the app without re-deploying code.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native B2B & individual client support (CUI/CNP and Billing Address management).
* **Legal Data Integrity & Protected Records**: Deletion guardrails preventing accidental removal of programs or students with active signed contracts or payment history.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering, and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**: Auto-enforces **Paid** status when total installment amounts are covered and generates bilingual PDF receipts.

---

## 🎨 What's New in Version 1.5.12

- 🏢 **1-Tap ANAF CUI/CIF Live Auto-Lookup (F-01)**:
  - **Official ANAF V9 Integration**: Directly queries Romania's public fiscal service (`/api/PlatitorTvaRest/v9/tva`), stripping `RO` prefixes and validating 2–10 digit CUIs.
  - **Instant B2B Auto-Population**: Automatically fills official company name (*Denumire*), registered headquarters (*Adresă sediu social*), Trade Register number (*nrRegCom*), and phone number with 1 tap.
  - **VAT & Inactivity Status Banners**: Displays real-time toast confirmation highlighting VAT payer status (*Plătitor TVA* vs *Neplătitor TVA*) and warnings if an entity is fiscally suspended/inactive.
  - **Inline UI Actions**: Added blue 🔍 search action buttons with integrated spinner loaders directly inside `EditStudentDialog` and `EnrolledStudentsView`.
  - **Smart Paste Synergy**: Pairs with the existing smart text parser to detect pasted CUIs and resolve full company profiles in seconds.
- 🌐 **Multi-Platform Web CORS Relays**:
  - **Production Web Proxy**: Added `web/api/anaf.php` deployed to `apps.qualiadept.eu/agreemint/` on the same origin, eliminating browser CORS issues in production.
  - **Node Server Relay**: Added `GET /api/anaf/:cui` to `server/whatsapp_bot_server.js` with full CORS support.
  - **Supabase PostgreSQL Relay**: Added `lookup_cui_anaf` function in `supabase_rpc_setup.sql`.
- 🧪 **Complete Test Pyramid (116/116 Tests Passing)**:
  - **Unit Tests**: [`test/unit/anaf_service_test.dart`](file:///c:/Users/George/dev/agreemint/test/unit/anaf_service_test.dart) (5 tests covering sanitization, valid/invalid CUI, active/inactive entities, and VAT status).
  - **Widget Integration Tests**: [`test/widget/anaf_cui_lookup_widget_test.dart`](file:///c:/Users/George/dev/agreemint/test/widget/anaf_cui_lookup_widget_test.dart) (3 tests verifying search button rendering, empty CUI warnings, and segment switching).
  - **E2E Integration Tests**: [`integration_test/app_e2e_test.dart`](file:///c:/Users/George/dev/agreemint/integration_test/app_e2e_test.dart) (verifying end-to-end model mapping and payload parsing).
- 📦 **Version Bump**: Promoted release version to `v1.5.12` (`1.5.12+134`).

