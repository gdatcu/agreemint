# 🚀 Agreemint v1.0.59 Release Notes

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

## 🎨 What's New in Version 1.0.59

- 🧾 **1-Tap Accounting & ANAF Batch CSV Export (`AccountingExportService`)**:
  - Added an **Export Accounting CSV (ANAF)** button to the **Analytics Summary** header.
  - Interactive Date Range Selector dialog (*All Time*, *Current Month*, *Last Month*, *Year to Date*).
  - Encoded with **UTF-8 BOM** so Romanian diacritics (`ă`, `î`, `ș`, `ț`, `â`) open natively in Microsoft Excel.
  - Complete Romanian tax/accounting fields included: `Data Platii`, `Nume Client / Firma`, `Tip Client`, `CUI / CIF`, `Reg. Com.`, `Program Mentorat`, `Transa`, `Suma Platita`, `Moneda`, `Echivalent RON`, `Metoda Plata`, `Numar Factura SOLO`, `URL Factura SOLO`, `URL Chitanta`.
  - 1-click direct download on Web and native share sheet on Mobile.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.59` (`1.0.59+59`).


