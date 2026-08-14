# 🚀 Agreemint v1.0.23 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native support for both standard individual clients and business entities (PFA/SRL) with automated CUI/CIF, Reg. Com., and Billing Address management.
* **Legal Data Integrity & Protected Records**: Deletion guardrails preventing accidental removal of programs or students with active signed contracts or payment history.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Native bilingual PDF receipt generation with mentor signature capture.
  * Direct PDF retrieval from Supabase Storage for signed receipts to guarantee signature retention.

---

## 🎨 What's New in Version 1.0.23

- 📱 **Android Native Push Notifications**:
  - `flutter_local_notifications` integration with high-importance Android Notification Channel (`Overdue Payment Alerts`).
  - Native heads-up notification banners in the Android status bar when past due payments exist.
  - Automatic prompt for Android 13+ (`POST_NOTIFICATIONS`) permission.
- 💬 **1-Click WhatsApp Payment Reminders**:
  - Green WhatsApp action button on `PaymentTrackerView` and `PendingDashboardView` items.
  - Automatically formats student phone numbers and opens WhatsApp with polite prefilled Romanian reminder text.
- ⚠️ **Overdue Payment Alerts & Visual Highlighting**:
  - Prominent red **Overdue** status badges on installments past their due date.
  - Top **Overdue Alert Banner** on `PendingDashboardView`.
  - Overdue counter badge on the "Pending" bottom navigation bar icon.
- 📅 **Due Date Control & Settlement Locking**:
  - Interactive Date Picker added to the Record / Edit Payment dialog.
  - Settled `Paid` and `Refunded` installments locked against accidental editing or deletion.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.23` (`1.0.23+23`).


