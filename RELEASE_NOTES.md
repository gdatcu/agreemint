# 🚀 Agreemint v1.0.39 Release Notes

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

## 🎨 What's New in Version 1.0.39

- 🛠️ **Prospect Conversion Bug Fix**:
  - Removed invalid `'notes'` field from the `students` insert payload in `ProspectRepository.convertToStudent()`. Converts prospects to enrolled students with 100% success!
- 🔔 **Android Push Notifications for Prospect Follow-Ups**:
  - Implemented `NotificationService.checkAndNotifyProspectFollowUps()`. Sends daily Android heads-up alerts when prospects have follow-ups due today or overdue.
- 📐 **Prospect Notes Overflow & Layout Protection**:
  - Added line truncation (`maxLines: 4`) for long prospect notes to prevent horizontal layout overflow.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.39` (`1.0.39+39`).


