# 🚀 Agreemint v1.0.20 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering (`is_custom` one-off isolation), and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**:
  * Auto-enforces **Paid** status when total installment amounts are covered.
  * Native bilingual PDF receipt generation with mentor signature capture.
  * Direct PDF retrieval from Supabase Storage for signed receipts to guarantee signature retention.

---

## 🎨 What's New in Version 1.0.20

- 🛠️ **GitHub Actions Deployment Fix**: Corrected protocol (`ftps`) and default port (`21`) for `SamKirkland/FTP-Deploy-Action@v4.3.5` in `.github/workflows/release.yml`.
- 📜 **Contract Terms Preservation Snapshot**: Added a `details` JSON snapshot column to the `contracts` table and model. Stores all specific form parameters (IBAN, PFA address, student CNP, student address, CI details, course duration, curriculum technologies, payment arrangements, refund deadline, etc.) upon initial contract creation.
- ✒️ **100% PDF Fidelity Upon Client Signature**: Reuses draft terms snapshot from `contract.details` to preserve exact contract terms upon signing.
- 📦 **Dynamic Version Alignment**: Updated app version to `v1.0.20` (`1.0.20+20`).
