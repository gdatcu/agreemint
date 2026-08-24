# 🚀 Agreemint v1.5.0 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Dual-Channel Outgoing Notifications (WhatsApp & Email)**: Direct deep-linking WhatsApp notifications and transactional Resend emails with personalized templates for contract signing, installment payment reminders, receipts, and student follow-ups.
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

## 🎨 What's New in Version 1.5.0

- 💬 **Centralized WhatsApp Service (`WhatsAppService`)**:
  - Implemented automatic phone cleaning & Romanian national prefix formatting (`07xx` $\rightarrow$ `407...`).
  - Added conversational personalized templates for:
    - Contract Review & Signing Link.
    - Upcoming Payment Installment Reminders.
    - Payment Received Confirmation Receipts.
    - Enrolled Student General Follow-ups.
  - Zero-cost direct deep linking via `whatsapp://send` to protect personal accounts from spam filters.
- 📧 **Transactional Email Service with Resend API (`EmailService`)**:
  - Direct HTTP REST API integration with `https://api.resend.com/emails`.
  - Responsive, branded HTML email templates for contract review links, payment reminders, and payment receipts.
  - Configured environment variable `RESEND_API_KEY` (`resendApiKeyProvider`) with seamless in-app Business Settings fallback.
- ⚡ **Dual-Channel Action Controls Across UI**:
  - **Payment Tracker View**: 1-tap WhatsApp and Email buttons for pending reminders and paid installment receipts with real-time loading feedback.
  - **Pending Dashboard View**: Dual WhatsApp/Email reminder icons for all overdue and pending student installments.
  - **Enrolled Students View**: 1-tap WhatsApp check-in button on each student card.
  - **Contract Signing View**: Direct "Send via WhatsApp" and "Send via Email" action buttons alongside link sharing.
- 📦 **Version Bump**: Promoted release version to `v1.5.0` (`1.5.0+122`).
