# 🚀 Agreemint v1.5.4 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Dual-Channel Outgoing Notifications (WhatsApp & Email)**: Direct deep-linking WhatsApp notifications and transactional Resend emails with personalized Romanian templates for contract signing, installment payment reminders, receipts, and student follow-ups.
* **Mentorship Cohort Management**: Create, edit, and track mentorship cohorts in **RON** and **EUR**.
* **Student & Enrollment Roster**: Manage active students and enrollments with automatic history archiving upon program deletion.
* **Prospect Follow-ups & Lead Pipeline CRM**: Lead tracking with top KPI metrics (Total Leads, Due/Overdue, Contacted, Converted & Conversion Rate %, Lost), live search, sorting, and 1-tap WhatsApp outreach.
* **1-Tap Mentorship Graduation Certificate Generator**: Official, branded QualiAdept Mentorship Completion Certificates with customizable course hours, sessions count, bilingual RO/EN translations, public verification portal, and PDF preview.
* **Live Search & Multi-Filter Roster**: Real-time instant search by Student Name, Email, Phone, and CUI/CIF, with multi-status filter chips.
* **Custom Contract & Business Settings Screen**: Configure company details, default contract terms, Resend API keys, and default mentor signature PNG directly inside the app without re-deploying code.
* **B2B & Individual Client Support (PF / PFA / SRL)**: Native B2B & individual client support (CUI/CNP and Billing Address management).
* **Legal Data Integrity & Protected Records**: Deletion guardrails preventing accidental removal of programs or students with active signed contracts or payment history.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation, dynamic sequence numbering, and on-screen student signature capture.
* **Live Frankfurter API Currency Exchange**: Automatic real-time BNR/ECB exchange rate conversion (`EUR` $\rightarrow$ `RON`).
* **Flexible Payment Schedule & Receipt Tracking**: Auto-enforces **Paid** status when total installment amounts are covered and generates bilingual PDF receipts.

---

## 🎨 What's New in Version 1.5.4

- 🔗 **Direct Contract & Invoice Links in Payment Reminders (WhatsApp & Email)**:
  - Both WhatsApp messages and Email notifications now automatically attach direct links to the **Signed Contract** (terms & agreement) and the **SOLO Fiscal Invoice** (if uploaded to Supabase).
- ⏱️ **Smart Dynamic Due Date Phrasing**:
  - Automatically calculates relative days between the notification dispatch date and the payment due date:
    - *0 zile*: **„cu scadența astăzi, 24.08.2026”**
    - *1 zi*: **„cu scadența mâine, 25.08.2026”**
    - *X zile viitoare*: **„cu scadența în X zile (pe data de DD.MM.YYYY)”**
    - *1 zi întârziere*: **„care a înregistrat scadența ieri, DD.MM.YYYY (restantă de 1 zi)”**
    - *X zile întârziere*: **„care a depășit termenul de scadență cu X zile”**
- 📦 **Version Bump**: Promoted release version to `v1.5.4` (`1.5.4+126`).
