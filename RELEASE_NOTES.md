# 🚀 Agreemint v1.0.10 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule Tracker**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Complete editing flexibility for all payment records.
  * Follow-up installment creation for partial payments & custom single installment additions.

---

## 🎨 What's New in Version 1.0.10

- 🧪 **Comprehensive Automated Testing Suite**: Added 34 unit, integration, and widget test cases spanning data models, controllers, business rules, and UI views (`mocktail`, `integration_test`).
- 🛡️ **CI/CD Quality Gate**: Integrated `flutter test` execution directly into GitHub Actions release workflow to block regressed builds before APK / Web deployment.
- 📊 **Standalone Windows HTML Coverage Generator**: Created `tool/generate_html_report.dart` to generate interactive code coverage reports (`coverage/html/index.html`).
- 🔧 **Production Supabase Credential Fallback**: Resolved web portal `Missing Configuration` screen with graceful credential fallback.
- 📦 **Dynamic Version Alignment**: Updated app version to `v1.0.10` (`1.0.10+10`).
