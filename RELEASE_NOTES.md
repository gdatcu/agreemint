# 🚀 Agreemint v1.5.10 Release Notes

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

## 🎨 What's New in Version 1.5.10

- ✍️ **Universal Profile Signature Integration**:
  - **Business Settings Default Signature Across All Screens**: Connects your saved mentor signature across Payment Receipts, Contracts, and Certificates.
  - **Receipt Signing Modal (`ReceiptSignatureDialog`)**: Preloads your saved signature automatically with 1-click **"Aplică / Confirm"** confirmation, visual status banner, and the ability to draw a custom signature or restore the profile signature.
  - **Contract Issuance Guard Fix**: Fixed the contract issuance guard in `ContractSigningView` so issuing contracts using your saved Business Settings profile signature works seamlessly without requiring manual strokes on the canvas.
- 📱 **Comprehensive Mobile Viewport & RenderFlex Overflow Fixes**:
  - **Student Roster Action Buttons (`EnrolledStudentsView`)**: Replaced rigid action `Row` with responsive `Wrap`, preventing horizontal overflows on narrow screens (e.g. Samsung S8+ / 360px).
  - **Pending Dashboard Student Cards (`PendingDashboardView`)**: Added `Expanded` with text ellipsis on student names to eliminate card overflows.
  - **Edit Student Modal (`EditStudentDialog`)**: Replaced horizontal client type `SegmentedButton` with a clean responsive layout and optimized the diacritics button into a compact tooltip icon button.
  - **Business Settings Integration Cards (`BusinessSettingsView`)**: Made headers for SOLO bookmarklet, Discord alerts, and Email notifications fully responsive.
- 📦 **Version Bump**: Promoted release version to `v1.5.10` (`1.5.10+132`).
