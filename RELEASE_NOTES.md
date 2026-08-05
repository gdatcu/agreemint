# 🚀 Agreemint v1.0.19 Release Notes

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

## 🎨 What's New in Version 1.0.19

- 📜 **Contract Terms Preservation Snapshot**: Added a `details` JSON snapshot column to the `contracts` table and model. Stores all specific form parameters (IBAN, PFA address, student CNP, student address, CI details, course duration, curriculum technologies, payment arrangements, refund deadline, etc.) upon initial contract creation.
- ✒️ **100% PDF Fidelity Upon Client Signature**: Updated `ClientWebSignatureView` and `EnrollmentContractController` so that generating the final signed contract PDF reuses 100% of the exact draft terms snapshot from `contract.details`, ensuring the client signature is the ONLY change in the executed document.
- 🗄️ **Supabase SQL Schema Update**: Added `ALTER TABLE contracts ADD COLUMN IF NOT EXISTS details JSONB;` to `supabase_rls_policies.sql`.
- 🧪 **Unit Test Coverage**: Added comprehensive unit tests for `ContractModel.details` JSON serialization/deserialization and controller update mocks.
- 📦 **Dynamic Version Alignment**: Updated app version to `v1.0.19` (`1.0.19+19`).
