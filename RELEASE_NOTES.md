# 🚀 Agreemint v1.0.34 Release Notes

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

## 🎨 What's New in Version 1.0.34

- 🔗 **Full Signed Contract Database Join (`contracts(*)`)**:
  - Updated `PaymentRepository.fetchGlobalPendingPayments()` to join `contracts(*)`. Ensures signed contract links are ALWAYS loaded and attached in 1-tap WhatsApp notifications on the Pending Dashboard.
- 💬 **Generous Paragraph Spacing & Unicode Escaped Icons (`\u{1F916}`, `\u{1F4C4}`, `\u{270D}\u{FE0F}`)**:
  - Added double linebreaks (`\n\n`) between document links for clean, spacious readability.
  - Formatted icons with explicit Dart Unicode escapes for 100% clean URL encoding.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.34` (`1.0.34+34`).


