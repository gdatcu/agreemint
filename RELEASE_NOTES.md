# 🚀 Agreemint v1.0.21 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native support for both standard individual clients and business entities (PFA/SRL) with automated CUI/CIF, Reg. Com., and Billing Address management.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Native bilingual PDF receipt generation with mentor signature capture.
  * Direct PDF retrieval from Supabase Storage for signed receipts to guarantee signature retention.

---

## 🎨 What's New in Version 1.0.21

- 🏢 **B2B Client Support (PFA / SRL)**:
  - Extended `StudentModel`, `StudentRepository`, and enrollment flow to handle `clientType` (`PF` vs `PFA`/`SRL`), `cui`, `regCom`, and `billingAddress`.
  - Upgraded Add Student UI with a Material 3 `SegmentedButton` to quickly switch between Individual (PF) and PFA/Company modes.
  - Form fields (CUI, Reg. Com., Billing Address) adapt dynamically depending on the selected client type.
  - Student list cards now display client type badges (`PF` vs `PFA`/`SRL`) and CUI.
- 📜 **B2B Contract Layouts & PDF Generator**:
  - Upgraded PDF Generator (`generateContractPdf`) to format Section 1.2 ("BENEFICIARUL / BENEFICIARY") for PFA/SRL entities with Entity Name, CUI/CIF, Reg. Com. No., and Registered Address.
  - Optional CNP/CI validation during contract issuance for B2B clients.
  - Full details snapshot preservation in Supabase ensuring 100% PDF layout consistency before and after client web signing.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.21` (`1.0.21+21`).

