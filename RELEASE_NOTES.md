# 🚀 Agreemint v1.0.17 Release Notes

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

## 🎨 What's New in Version 1.0.17

- ✍️ **Receipt Signature Retention**: Stored signed receipt PDFs are retained and fetched directly from Supabase Storage so mentor signatures are permanently displayed when re-opening receipts.
- 🔒 **Receipt Immutability & Status Tracking**: Signed receipts display a green `✓ Semnat / Signed` badge and disable re-signing or editing once executed.
- 📱 **Persistent App Update Dismissal**: Update notice dismissals are remembered per release tag via `SharedPreferences`, preventing repetitive update banners across app relaunches.
- 🎨 **Overlapping UI Layout Fix**: Redesigned payment installment list tiles to prevent text collision over action buttons.
- ⚡ **Dialog Lifecycle & Progress Overlay**: Replaced double-dialog patterns with root navigator dismissal and inline modal progress overlays during receipt signing.
- 📦 **Dynamic Version Alignment**: Updated app version to `v1.0.17` (`1.0.17+17`).
