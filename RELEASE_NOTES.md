# 🚀 Agreemint v1.5.13 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **1-Tap ANAF CUI/CIF Live Auto-Lookup**: Instant company retrieval from Romania's official ANAF V9 registry, automatically filling company legal name, seat address, and Trade Register number.
* **SOLO / Invoice Smart Link Parser (F-03)**: Instant detection, extraction, and auto-filling of invoice numbers, series, web links, amounts, and issue dates from copied SOLO links or WhatsApp/email messages.
* **Historical FX Rate Snapshotting & Accounting Export (F-02)**: Immutable BNR/ECB FX rate locking upon payment creation, multi-currency calculations, and 1-tap fiscal CSV accounting export.
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

## 🎨 What's New in Version 1.5.13

- ⚡ **SOLO / Invoice Smart Link Parser (F-03)**:
  - **`InvoiceSmartLinkParser` Engine**: Robust regex-powered parser identifying series, invoice numbers, web URLs, amounts, currencies, and issue dates from any raw text, clipboard content, or message snippet.
  - **Comprehensive SOLO Link Support**: Natively extracts from `app.solo.ro/invoices/SL-10492`, `/invoices/10492`, `/i/10492`, `/facturi/view/...`, `/factura/SL-2024-10492`, query params, and PDF storage links.
  - **Smart Autofill & Series Normalization**: Automatically formats series/number pairs (e.g. `SL-10492`, `SOLO-10492`, `SL-2024-10492`) and identifies platforms (`SOLO`, `Smartbill`, `Oblio`, `FGO`).
  - **`SoloInvoiceDialog` UI Overhaul**:
    - **1-Tap Clipboard Autofill**: Automatically reads system clipboard and populates invoice fields in 1 click.
    - **Inline Separation & Auto-Detect**: Pasting a full URL or mixed text into the invoice number field automatically extracts the number and moves the URL into the link field.
    - **Visual Confirmation**: Green status badge displaying detected platform, invoice number, and parsed monetary amounts.
    - **Supabase Cloud PDF Storage**: Integrated file picker and cloud upload to attach physical PDF invoices.
  - **Roster Workflow Integration (`EnrolledStudentsView`)**:
    - Installment breakdown dialog now features direct `[⚡ Atașează / Parsează]` and `[Editează]` actions for missing or existing invoices without navigating away from the student list.
- 💱 **Historical FX Rate Snapshotting on Payment Creation & Accounting Export (F-02)**:
  - Immutable historical exchange rate locking on payment creation for EUR programs.
  - Unified CSV accounting export in `AccountingExportService` with locked FX conversion rates.
- 🧪 **Full Test Pyramid (140/140 Tests Passing)**:
  - **Unit Tests**: [`test/unit/invoice_smart_link_parser_test.dart`](file:///c:/Users/George/dev/agreemint/test/unit/invoice_smart_link_parser_test.dart) (14 tests covering URLs, series-year formats, query params, WhatsApp messages, amounts, and dates).
  - **Widget Tests**: [`test/widget/solo_invoice_dialog_test.dart`](file:///c:/Users/George/dev/agreemint/test/widget/solo_invoice_dialog_test.dart) (4 tests validating UI rendering, smart link extraction, inline paste auto-detect, and validation guardrails).
  - 100% test suite passing with 0 regressions.
- 📦 **Version Bump**: Promoted release version to `v1.5.13` (`1.5.13+135`).


