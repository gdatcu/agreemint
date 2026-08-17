# 🚀 Agreemint v1.0.48 Release Notes

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

## 🎨 What's New in Version 1.0.48

- 🔐 **QualiAdept PIN Gateway Web Viewer**:
  - Implemented public `/view-doc` web route (`DocGatewayView`) featuring 4-digit PIN verification.
  - When clients click WhatsApp links for receipts, contracts, or invoices, they are prompted to enter the last 4 digits of their phone number (`9506`) before the PDF document renders!
  - Displays instant error feedback if an incorrect PIN is entered (`❌ PIN incorect. Vă rugăm să introduceți ultimele 4 cifre ale numărului de telefon`).
- 💬 **Integrated Gateway URLs in All Shared Messages**:
  - Automatically wraps receipt, contract, and SOLO invoice links in `buildDocGatewayUrl` across all WhatsApp delivery templates.
- 📦 **Dynamic Version Bump**: Updated app version to `v1.0.48` (`1.0.48+48`).


