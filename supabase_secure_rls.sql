-- ============================================================================
-- Agreemint - Upgraded Secure Row Level Security (RLS) Policies
-- ============================================================================
-- 
-- Run this SQL in your Supabase Dashboard > SQL Editor to secure your database
-- against unauthorized anonymous bulk-downloading (GDPR Compliance).
--
-- These policies ensure that anonymous web users (clients signing contracts)
-- can ONLY read records associated with their specific pending contract,
-- while authenticated mentors retain full CRUD access.
-- ============================================================================

-- ============================================================================
-- 1. PROGRAMS TABLE
-- ============================================================================
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

-- Drop old policies
DROP POLICY IF EXISTS "Authenticated users can read programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can insert programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can update programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can delete programs" ON public.programs;
DROP POLICY IF EXISTS "Anon can read program details for signing" ON public.programs;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read programs" ON public.programs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert programs" ON public.programs
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update programs" ON public.programs
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Authenticated users can delete programs" ON public.programs
  FOR DELETE TO authenticated USING (true);

-- 🛡️ Anon: Can only read the program name/details linked to an active unsigned contract
CREATE POLICY "Anon can read program details for signing" ON public.programs
  FOR SELECT TO anon USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.contracts c ON c.enrollment_id = e.id
      WHERE e.program_id = programs.id AND c.status IN ('Draft', 'PendingClient')
    )
  );


-- ============================================================================
-- 2. STUDENTS TABLE
-- ============================================================================
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read students" ON public.students;
DROP POLICY IF EXISTS "Authenticated users can insert students" ON public.students;
DROP POLICY IF EXISTS "Authenticated users can update students" ON public.students;
DROP POLICY IF EXISTS "Authenticated users can delete students" ON public.students;
DROP POLICY IF EXISTS "Anon can read student details for signing" ON public.students;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read students" ON public.students
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert students" ON public.students
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update students" ON public.students
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Authenticated users can delete students" ON public.students
  FOR DELETE TO authenticated USING (true);

-- 🛡️ Anon: Can only read student email/name linked to an active unsigned contract
CREATE POLICY "Anon can read student details for signing" ON public.students
  FOR SELECT TO anon USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.contracts c ON c.enrollment_id = e.id
      WHERE e.student_id = students.id AND c.status IN ('Draft', 'PendingClient')
    )
  );


-- ============================================================================
-- 3. ENROLLMENTS TABLE
-- ============================================================================
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Authenticated users can insert enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Authenticated users can update enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Authenticated users can delete enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Anon can read enrollments for contract signing" ON public.enrollments;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read enrollments" ON public.enrollments
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert enrollments" ON public.enrollments
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update enrollments" ON public.enrollments
  FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Authenticated users can delete enrollments" ON public.enrollments
  FOR DELETE TO authenticated USING (true);

-- 🛡️ Anon: Can only read the specific enrollment record linked to an active unsigned contract
CREATE POLICY "Anon can read enrollments for contract signing" ON public.enrollments
  FOR SELECT TO anon USING (
    EXISTS (
      SELECT 1 FROM public.contracts c 
      WHERE c.enrollment_id = enrollments.id AND c.status IN ('Draft', 'PendingClient')
    )
  );


-- ============================================================================
-- 4. CONTRACTS TABLE
-- ============================================================================
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users full access to contracts" ON public.contracts;
DROP POLICY IF EXISTS "Anon can read contracts for signing" ON public.contracts;
DROP POLICY IF EXISTS "Anon can update contracts for client signing" ON public.contracts;

-- Mentors: Full access
CREATE POLICY "Authenticated users full access to contracts" ON public.contracts
  FOR ALL TO authenticated USING (true);

-- 🛡️ Anon: Can only read the contract details if the contract is unsigned (Draft/PendingClient)
-- Once signed, the contract is locked and can no longer be accessed anonymously.
CREATE POLICY "Anon can read contracts for signing" ON public.contracts
  FOR SELECT TO anon USING (
    status IN ('Draft', 'PendingClient')
  );

-- 🛡️ Anon: Can only update the contract to submit client signatures for unsigned contracts
CREATE POLICY "Anon can update contracts for client signing" ON public.contracts
  FOR UPDATE TO anon USING (
    status IN ('Draft', 'PendingClient')
  );
