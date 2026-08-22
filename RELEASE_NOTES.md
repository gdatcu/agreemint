# 🚀 Agreemint v1.4.8 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **Prospect Follow-ups & Lead Pipeline CRM**: Lead tracking with top KPI metrics (Total Leads, Due/Overdue, Contacted, Converted & Conversion Rate %, Lost), live item counts on filter tabs (`Due/Overdue (0)`, `Upcoming (12)`, `Contacted (0)`, `Converted (1)`, `Lost (2)`, `All (15)`), live search, sorting, 1-tap contact logging with date shortcuts (`+2d`, `+7d`, `Next Week`), and WhatsApp outreach.
* **1-Tap Mentorship Graduation Certificate Generator**: Official, branded QualiAdept Mentorship Completion Certificates with customizable course hours, sessions count, session duration (e.g. 2.5h), clean bilingual RO & EN translations, public QR verification portal (`/verify-cert`), mentor signature auto-fill, PDF preview, and WhatsApp sharing.
* **Live Search & Multi-Filter Roster**: Real-time instant search by Student Name, Email, Phone, and CUI/CIF, with multi-status filter chips (Signed, Unsigned, Refunded, Archived, No Plan, Missing SOLO).
* **Custom Contract & Business Settings Screen**: Configure company details (CUI/CIF, Reg. Com., Sediu, IBAN, Bank Name), default contract terms, and default mentor signature PNG directly inside the app without re-deploying code.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native B2B & individual client support (CUI/CNP and Billing Address management).
* **Legal Data Integrity & Protected Records**: Deletion guardrails preventing accidental removal of programs or students with active signed contracts or payment history.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Native bilingual PDF receipt generation with mentor signature capture.

---

## 🎨 What's New in Version 1.4.8

- 📧 **Direct Resend API Routing for 100% Reliable Email Delivery**:
  - Removed failing third-party CORS proxy and switched all email dispatches directly to Resend's REST endpoint (`https://api.resend.com/emails`), enabling instantaneous inbox delivery.
  - Added comprehensive delivery logging for all contract signed and test email alerts.
- ✍️ **Bulletproof Signature Fallback Chain**:
  - Made saved profile signature fallback fail-safe (`pngBytes ??= _savedMentorSignatureBytes`), ensuring contract generation never blocks or fails with "Please draw your signature first".
  - Wrapped signature canvas overlay with `IgnorePointer` for seamless gesture passthrough.
- 📦 **Patch Version Bump**: Promoted release version to `v1.4.8` (`1.4.8+120`).
