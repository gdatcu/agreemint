# 🚀 Agreemint v1.5.5 Release Notes

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

## 🎨 What's New in Version 1.5.5

- 🔐 **Agreemint Secure Document Gateway & OTP Protection**:
  - Encapsulated raw storage links inside secured Agreemint Gateways:
    - **Contract Signing / Review Portal (`#/sign/<id>`)**: Enforces 6-digit email OTP verification before granting access to contract terms and signed PDF download.
    - **SOLO Invoice PIN Gateway (`#/view-doc`)**: Requires the student's 4-digit phone PIN (last 4 digits of phone number) to unlock, view, and download fiscal invoices.
  - Added dedicated security instruction badges in both WhatsApp messages and Email notifications.
- ⏱️ **Smart Dynamic Due Date Calculation**: Automatically phrases relative due dates (`astăzi`, `mâine`, `în X zile`, `restantă de X zile`).
- 📦 **Version Bump**: Promoted release version to `v1.5.5` (`1.5.5+127`).
