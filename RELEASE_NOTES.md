# 🚀 Agreemint v1.0.18 Release Notes

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

## 🎨 What's New in Version 1.0.18

- 🔒 **Permanent Contract & Signature Storage URLs**: Replaced 1-hour expiring signed storage URLs (`createSignedUrl`) with permanent public URLs (`getPublicUrl`), fixing HTTP 400 `InvalidJWT` errors on contract access.
- 🔄 **Retroactive URL Normalization**: Added automatic conversion in `ContractModel.fromJson` to transform any legacy expiring signed URLs (`/object/sign/` with `?token=...`) into permanent public URLs (`/object/public/`), restoring access to all previously signed contracts.
- 🧪 **Unit Test Coverage**: Added tests for contract URL normalization and public URL generation.
- 📦 **Dynamic Version Alignment**: Updated app version to `v1.0.18` (`1.0.18+18`).
