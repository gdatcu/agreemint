# Agreemint - Mentor Contract & Payment Tracker

[![Build & Release](https://github.com/gdatcu/agreemint/actions/workflows/release.yml/badge.svg)](https://github.com/gdatcu/agreemint/actions/workflows/release.yml)

A modern, cross-platform mobile & web application built for course creators and mentors to manage educational programs, enroll students, generate & sign bilingual legal contracts, and track installment payment schedules.

---

## 🌟 Key Features

* **Mentoring Program Management**: Create, edit, and archive mentorship cohorts. Supports programs in **RON** and **EUR**.
* **Student & Enrollment Management**: Track active students and enrollments across multiple programs with automatic history archiving.
* **Bilingual Legal Contracts (RO/EN)**: Native PDF contract generation with on-screen signature capture and automatic public Supabase Storage upload.
* **Custom Contract Sequence Engine**: Automatic incrementing contract numbering with isolated one-off custom contract numbers (`is_custom`).
* **Frankfurter API Exchange Rate Integration**: 100% free, real-time BNR/ECB EUR $\rightarrow$ RON currency exchange rate conversion for legal contract drafting.
* **Flexible Payment Schedule Tracker**:
  * Auto-enforces **Paid** status when full installment amounts are covered.
  * Full editing flexibility for all installment records.
  * Automatic follow-up installment creation when recording partial payments.
  * Manual single/custom installment additions.
* **100% Free Tech Stack**: Built entirely on free-tier services and open-source frameworks.

---

## 🛠️ Tech Stack & Architecture

* **Frontend Framework**: Flutter 3 (Web, Android, iOS)
* **Backend / Database**: Supabase (PostgreSQL, Storage, RLS)
* **State Management**: Flutter Riverpod with `riverpod_annotation` and code generation
* **Routing**: `go_router`
* **Currency Exchange API**: [Frankfurter API](https://api.frankfurter.dev) (100% free, no API key required)
* **PDF & Signature**: `pdf`, `printing`, `signature`, `path_provider`

### Architecture Guidelines
Follows a **Feature-First (Domain-Driven) Architecture**:
```
lib/
├── core/                  # App theme, routing, constants, Frankfurter service
└── features/              # Grouped by domain
    ├── programs/          # Models, Repositories, Controllers, Views
    ├── students/          # Student management & enrollments
    ├── contracts/         # Contract generation, sequence logic, PDF signing
    └── payments/          # Payment schedule & tracking
```

---

## 🗄️ Supabase Database Setup

Run the following SQL migrations in your Supabase SQL Editor (`Dashboard -> SQL Editor -> New Query`):

```sql
-- 1. Create programs table with currency support
CREATE TABLE IF NOT EXISTS programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  total_price NUMERIC(10, 2) NOT NULL,
  currency TEXT DEFAULT 'RON',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create contracts table with custom contract sequence flag
CREATE TABLE IF NOT EXISTS contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id UUID REFERENCES enrollments(id) ON DELETE CASCADE,
  contract_number INT NOT NULL,
  pdf_url TEXT,
  signature_url TEXT,
  signed_date TIMESTAMPTZ,
  is_custom BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add sequence helper RPCs
CREATE OR REPLACE FUNCTION get_next_contract_number() 
RETURNS INT AS $$
  SELECT COALESCE(MAX(contract_number), 0) + 1 FROM contracts WHERE is_custom IS NOT TRUE;
$$ LANGUAGE SQL;
```

---

## 🚀 Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/gdatcu/agreemint.git
   cd agreemint
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch locally (Web / Desktop / Emulator)**:
   ```bash
   flutter run -d chrome
   ```

---

## 📦 Building Releases & CI/CD Pipeline

### 🤖 Automated GitHub Releases

Automated releases trigger when a new version tag (e.g. `v1.0.0`) is pushed to GitHub:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically builds:
* 🟢 **Android APK** (`app-release.apk`)
* 🟢 **Android AppBundle** (`app-release.aab`)
* 🟢 **Web Bundle Zip** (`web-release.zip`)

And attaches all three artifacts directly to the GitHub Release.

---

## 🌐 Deploying Web Build to `qualiadept.eu/agreemint`

To deploy the compiled web application to your web host server (`https://apps.qualiadept.eu/agreemint/`):

### Option A: Manual Upload via FTP/cPanel
1. Build the production web bundle locally:
   ```bash
   flutter build web --base-href "/agreemint/" --release
   ```
2. Upload the contents of `build/web/` directly to your web server root folder:
   ```
   /public_html/agreemint/  (or /var/www/html/agreemint/)
   ```
3. Ensure `.htaccess` (or NGINX config) routes sub-paths to `index.html`.

### Option B: Automated Server Deployment via GitHub Actions
Add your server credentials to GitHub Repository Secrets (`Settings -> Secrets and variables -> Actions`):
* `SERVER_HOST`: `apps.qualiadept.eu`
* `SERVER_USER`: `your_ftp_or_ssh_username`
* `SERVER_KEY` / `SERVER_PASSWORD`: `your_password_or_private_key`

Add an automated SCP/SFTP upload step to `.github/workflows/release.yml`:

```yaml
      - name: Deploy Web Build via SFTP
        uses: wlixcc/SFTP-Deploy-Action@v1.2.4
        with:
          username: ${{ secrets.SERVER_USER }}
          server: ${{ secrets.SERVER_HOST }}
          password: ${{ secrets.SERVER_PASSWORD }}
          local_path: 'build/web/*'
          remote_path: '/public_html/agreemint/'
          delete_remote: true
```
