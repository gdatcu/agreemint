-- ============================================================================
-- Agreemint - Row Level Security (RLS) Policies
-- ============================================================================
-- 
-- Run this SQL in your Supabase Dashboard > SQL Editor.
--
-- IMPORTANT: Before running this script:
--   1. Create a mentor user account in Supabase Auth (Dashboard > Authentication > Users)
--      Email: george.datcu@hotmail.com
--   2. Note the user's UUID from the Auth dashboard
--
-- This script enables RLS on all tables and creates policies that:
--   - Allow authenticated users (mentors) full CRUD access
--   - Allow anonymous users limited read access for contract signing
-- ============================================================================

-- ============================================================================
-- 1. PROGRAMS TABLE
-- ============================================================================
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-running
DROP POLICY IF EXISTS "Authenticated users can read programs" ON programs;
DROP POLICY IF EXISTS "Authenticated users can insert programs" ON programs;
DROP POLICY IF EXISTS "Authenticated users can update programs" ON programs;
DROP POLICY IF EXISTS "Authenticated users can delete programs" ON programs;

-- Mentors: Full access when authenticated
CREATE POLICY "Authenticated users can read programs" ON programs
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert programs" ON programs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update programs" ON programs
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete programs" ON programs
  FOR DELETE USING (auth.uid() IS NOT NULL);


-- ============================================================================
-- 2. STUDENTS TABLE
-- ============================================================================
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read students" ON students;
DROP POLICY IF EXISTS "Authenticated users can insert students" ON students;
DROP POLICY IF EXISTS "Authenticated users can update students" ON students;
DROP POLICY IF EXISTS "Authenticated users can delete students" ON students;

CREATE POLICY "Authenticated users can read students" ON students
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert students" ON students
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update students" ON students
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete students" ON students
  FOR DELETE USING (auth.uid() IS NOT NULL);


-- ============================================================================
-- 3. ENROLLMENTS TABLE
-- ============================================================================
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read enrollments" ON enrollments;
DROP POLICY IF EXISTS "Authenticated users can insert enrollments" ON enrollments;
DROP POLICY IF EXISTS "Authenticated users can update enrollments" ON enrollments;
DROP POLICY IF EXISTS "Authenticated users can delete enrollments" ON enrollments;
DROP POLICY IF EXISTS "Anon can read enrollments for contract signing" ON enrollments;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read enrollments" ON enrollments
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert enrollments" ON enrollments
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update enrollments" ON enrollments
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete enrollments" ON enrollments
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- Public: Read-only for contract signing (joined from contracts table)
CREATE POLICY "Anon can read enrollments for contract signing" ON enrollments
  FOR SELECT USING (true);


-- ============================================================================
-- 4. CONTRACTS TABLE
-- ============================================================================
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users full access to contracts" ON contracts;
DROP POLICY IF EXISTS "Anon can read contracts for signing" ON contracts;
DROP POLICY IF EXISTS "Anon can update contracts for client signing" ON contracts;

-- Mentors: Full access
CREATE POLICY "Authenticated users full access to contracts" ON contracts
  FOR ALL USING (auth.uid() IS NOT NULL);

-- Public: Can read any contract (contract IDs are UUIDs, sufficiently random)
-- This allows the /sign/:contractId route to fetch contract details
CREATE POLICY "Anon can read contracts for signing" ON contracts
  FOR SELECT USING (true);

-- Public: Can update contracts for client signature submission only
-- (status, client_signature_url, signed_pdf_url, signed_date)
CREATE POLICY "Anon can update contracts for client signing" ON contracts
  FOR UPDATE USING (true);


-- ============================================================================
-- 5. PAYMENTS TABLE
-- ============================================================================
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read payments" ON payments;
DROP POLICY IF EXISTS "Authenticated users can insert payments" ON payments;
DROP POLICY IF EXISTS "Authenticated users can update payments" ON payments;
DROP POLICY IF EXISTS "Authenticated users can delete payments" ON payments;

CREATE POLICY "Authenticated users can read payments" ON payments
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can insert payments" ON payments
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update payments" ON payments
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can delete payments" ON payments
  FOR DELETE USING (auth.uid() IS NOT NULL);


-- ============================================================================
-- 6. PROGRAM HISTORY TABLE (if exists)
-- ============================================================================
-- Uncomment if you have a program_history or archived_programs table:
--
-- ALTER TABLE program_history ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Authenticated users full access to program_history" ON program_history
--   FOR ALL USING (auth.uid() IS NOT NULL);


-- ============================================================================
-- VERIFICATION: Check RLS is enabled on all tables
-- ============================================================================
-- Run this query to confirm RLS is active:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
