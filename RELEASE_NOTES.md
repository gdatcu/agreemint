# 🚀 Agreemint v1.0.9 Release Notes

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

## 🎨 What's New in Version 1.0.9

- 🔧 **Fixed Production Supabase Credential Fallback**: Resolved the web portal `Missing Configuration` screen by gracefully falling back to production Supabase credentials when `--dart-define` secrets are empty during CI build.
- 🔒 **Student Deletion Protection & Confirmation**: Explicit confirmation modal for unsigned student deletion while locking deletion for students with signed contracts (`canBeDeleted`).
- 🔐 **Enhanced Access Control & Mentor Auth**: Refined access control views and mentor authentication state handling.
- 📊 **Advanced Analytics & Financial Dashboard**: Enhanced financial metrics, currency summaries, and installment performance tracking.
- 🖋️ **Web Signature & Public Contract Verification**: Improved client web signature flow and contract signature validation.
- 📦 **Dynamic Version Alignment**: Bumped app version to `v1.0.9` (`1.0.9+9`) with automated GitHub Release and FTP deployment workflows.
