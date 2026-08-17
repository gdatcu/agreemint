# 🚀 Agreemint v1.0.50 Release Notes

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

## 🎨 What's New in Version 1.0.50

- 📥 **Prominent Download PDF Buttons in PIN Web Gateway**:
  - Added a prominent **`📥 Descarcă PDF`** button in the top navigation header and custom action bar when a document is unlocked.
  - Allows clients to 1-tap download receipts, contracts, and invoices (`Chitanta_REC-2026.pdf`) directly to their phone or desktop.
- 🧹 **Clean Custom Action Bar (No Confusing Toggle Switch)**:
  - Replaced default PDF action controls with 3 clean, explicit actions: **`📥 Descarcă PDF`**, **`🖨️ Printează`**, and **`🔗 Deschide în Browser`**.
- 🌐 **100% Production Domain Guarantee**:
  - All WhatsApp delivery templates strictly generate `https://apps.qualiadept.eu/agreemint/#/view-doc?url=...`, ensuring client links never contain `localhost`.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.50` (`1.0.50+50`).


