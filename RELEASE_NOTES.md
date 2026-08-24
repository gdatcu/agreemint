# 🚀 Agreemint v1.5.6 Release Notes

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

## 🎨 What's New in Version 1.5.6

- 🔐 **Single Unified Secured Document Portal (`#/sign/<contractId>`)**:
  - Unified contract signing and payment/invoice tracking under a single secure gateway link.
  - **Dual Identity Verification Gate**: Access requires confirming the student's **Email Address**, **Last 4 Digits of Phone Number (PIN)**, and the **6-digit OTP Code** sent via Email.
  - **Executed Portal Display**: Once verified, displays both:
    1. **Contract Semnat (Signed Contract)** with 1-tap PDF preview & download.
    2. **Facturi Fiscale & Grafic Tranșe de Plată**: Real-time installment status (Plătit / În așteptare), due dates, direct download buttons for all uploaded SOLO invoices, and bank transfer IBAN details.
  - WhatsApp & Email payment reminders now dispatch a single unified secured portal link instead of fragmented links.
- 📦 **Version Bump**: Promoted release version to `v1.5.6` (`1.5.6+128`).
