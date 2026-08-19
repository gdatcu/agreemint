# 🚀 Agreemint v1.0.66 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **1-Tap Mentorship Graduation Certificate Generator**: Official, branded QualiAdept Mentorship Completion Certificates (RO/EN) with customizable course hours & sessions (default 50h: 20 sessions x 2.5h), public QR verification portal (`/verify-cert`), mentor signature auto-fill, PDF preview, and WhatsApp sharing.
* **Live Search & Multi-Filter Roster**: Real-time instant search by Student Name, Email, Phone, and CUI/CIF, with multi-status filter chips (Signed, Unsigned, Refunded, Archived, No Plan, Missing SOLO).
* **Custom Contract & Business Settings Screen**: Configure company details (CUI/CIF, Reg. Com., Sediu, IBAN, Bank Name), default contract terms, and default mentor signature PNG directly inside the app without re-deploying code.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native support for both standard individual clients and business entities (PFA/SRL) with automated CUI/CIF, Reg. Com., and Billing Address management.
* **Legal Data Integrity & Protected Records**: Deletion guardrails preventing accidental removal of programs or students with active signed contracts or payment history.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Native bilingual PDF receipt generation with mentor signature capture.

---

## 🎨 What's New in Version 1.0.66

- 📜 **Certificate Customization & Fixes**:
  - **Customizable Hours & Sessions**: Added interactive input fields for Course Hours (default 50h) and Sessions (default 20 sessions x 2.5h) with live PDF re-rendering.
  - **Public QR Code Verification Page (`/verify-cert`)**: Scanning certificate QR code opens a standalone public web page confirming official certificate validation and graduate details.
  - **Mentor Signature PNG Integration**: Automatic signature binding from Settings with quick "Add Signature" shortcut if missing.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.66` (`1.0.66+66`).


