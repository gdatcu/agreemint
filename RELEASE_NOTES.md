# 🚀 Agreemint v1.0.51 Release Notes

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

## 🎨 What's New in Version 1.0.51

- 📱 **Mobile Responsiveness Overhaul across All Core Views**:
  - 🛠️ **Prospect Follow-ups (`ProspectsView`)**: Resolved 154px horizontal overflow error on narrow mobile screens (360px–420px) by wrapping follow-up dates, phone numbers, and action buttons in responsive flex layouts (`Wrap`).
  - 🛠️ **Pending Dashboard (`PendingDashboardView`)**: Fixed 29px pixel overflow on due dates and status badges (`Overdue` / `Pending`).
  - 🛠️ **Enrolled Students (`EnrolledStudentsView`)**:
    - Converted cramped student roster list items into responsive card layouts to handle long business entity names (e.g. *BNET SYSTEMS EU S.R.L.*) without right-side clipping.
    - Added horizontal touch scrolling for top summary metric cards (`Total`, `Signed`, `Fully Paid`, `Retired`).
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.51` (`1.0.51+51`).


