# 🚀 Agreemint v1.5.11 Release Notes

Welcome to **Agreemint** - the all-in-one mobile and web management application for course creators, mentors, and educational program managers.

---

## 🌟 What the App Does & Key Features

* **Dual-Channel Outgoing Notifications (WhatsApp & Email)**: Direct deep-linking WhatsApp notifications and transactional Resend emails with personalized Romanian templates for contract signing, installment payment reminders, receipts, and student follow-ups.
* **Student Birthdays & Romanian Name Days (Onomastică)**: Automatic detection of student birthdays (derived deterministically from 13-digit Romanian CNP) and 14 Romanian Orthodox feast name days (including dynamic Floriile), with automated Discord notifications and 1-tap WhatsApp greetings.
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

## 🎨 What's New in Version 1.5.11

- 🎂 **Automated Student Birthdays & Name Days (Sărbători & Onomastică)**:
  - **Deterministic CNP Extraction**: Extracts birthday date and turning age accurately from 13-digit Romanian CNP across centuries (`1`/`2` $\rightarrow$ 1900s, `5`/`6` $\rightarrow$ 2000s).
  - **14 Romanian Orthodox Feast Days**: Full name-matching dictionary covering Sf. Vasile, Sf. Ioan Botezătorul, Sf. Gheorghe, Sf. Constantin și Elena, Sf. Petru și Pavel, Sf. Ilie, Sf. Maria, Sf. Alexandru, Sf. Dumitru, Sf. Mihail și Gavriil, Sf. Andrei, Sf. Nicolae, Sf. Ștefan, and dynamic **Floriile** (computed dynamically via Gregorian-Orthodox Easter algorithm).
  - **Smart First Name Personalization**: Intelligently identifies and addresses students by their given name (e.g. `Dumitrița` instead of surname `Bălan`) and matches celebration tokens.
  - **1-Tap WhatsApp Greetings**: Pre-composed polite Romanian greeting messages ready to send directly via WhatsApp.
  - **Automated Discord Alerts**: Scheduled daily notifications sent to the mentor's configured Discord webhook for upcoming celebrations (Today, Tomorrow, and Next 7 Days).
- 📱 **Roster UI Enhancements**:
  - **Upcoming Celebrations Banner**: Interactive, horizontally scrollable top bar highlighting upcoming celebrations with countdown badges (*Astăzi*, *Mâine*, *în X zile*).
  - **Header Birthday Icon & Full-Year Dialog**: Added top app bar 🎂 action button opening a modal with all upcoming celebrations across the year.
  - **Sărbători Filter Chip & Summary KPI**: Quick filter on the student roster to show only students with upcoming celebrations.
  - **Card Badge with Overflow Protection**: Celebration badge on individual student cards with responsive text ellipsis layout.
- 📦 **Version Bump**: Promoted release version to `v1.5.11` (`1.5.11+133`).

