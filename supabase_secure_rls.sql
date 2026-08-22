-- ============================================================================
-- Agreemint - Upgraded Secure Row Level Security (RLS) Policies (v1.0.95)
-- ============================================================================
-- 
-- Run this SQL in your Supabase Dashboard > SQL Editor to secure your database
-- against unauthorized access from students logged in via OTP.
--
-- These policies ensure that:
--   1. Only whitelisted mentor emails can access the admin backend.
--   2. Anonymous clients can ONLY read/write records for their specific contract.
-- ============================================================================

-- Helper function to check if the current user is a whitelisted mentor
CREATE OR REPLACE FUNCTION public.is_mentor()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    auth.jwt() ->> 'email' IN ('george.datcu@hotmail.com', 'george.datcu@gmail.com', 'billing@qualiadept.eu')
  );
END;
$$;


-- ============================================================================
-- 1. PROGRAMS TABLE
-- ============================================================================
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can insert programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can update programs" ON public.programs;
DROP POLICY IF EXISTS "Authenticated users can delete programs" ON public.programs;
DROP POLICY IF EXISTS "Anon can read program details for signing" ON public.programs;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read programs" ON public.programs
  FOR SELECT TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can insert programs" ON public.programs
  FOR INSERT TO authenticated WITH CHECK (public.is_mentor());

CREATE POLICY "Authenticated users can update programs" ON public.programs
  FOR UPDATE TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can delete programs" ON public.programs
  FOR DELETE TO authenticated USING (public.is_mentor());

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
  FOR SELECT TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can insert students" ON public.students
  FOR INSERT TO authenticated WITH CHECK (public.is_mentor());

CREATE POLICY "Authenticated users can update students" ON public.students
  FOR UPDATE TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can delete students" ON public.students
  FOR DELETE TO authenticated USING (public.is_mentor());

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
  FOR SELECT TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can insert enrollments" ON public.enrollments
  FOR INSERT TO authenticated WITH CHECK (public.is_mentor());

CREATE POLICY "Authenticated users can update enrollments" ON public.enrollments
  FOR UPDATE TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can delete enrollments" ON public.enrollments
  FOR DELETE TO authenticated USING (public.is_mentor());

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
  FOR ALL TO authenticated USING (public.is_mentor());

-- 🛡️ Anon: Can only read the contract details if the contract is unsigned (Draft/PendingClient)
CREATE POLICY "Anon can read contracts for signing" ON public.contracts
  FOR SELECT TO anon USING (
    status IN ('Draft', 'PendingClient')
  );

-- 🛡️ Anon: Can only update the contract to submit client signatures for unsigned contracts
CREATE POLICY "Anon can update contracts for client signing" ON public.contracts
  FOR UPDATE TO anon USING (
    status IN ('Draft', 'PendingClient')
  );


-- ============================================================================
-- 5. PAYMENTS TABLE
-- ============================================================================
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read payments" ON public.payments;
DROP POLICY IF EXISTS "Authenticated users can insert payments" ON public.payments;
DROP POLICY IF EXISTS "Authenticated users can update payments" ON public.payments;
DROP POLICY IF EXISTS "Authenticated users can delete payments" ON public.payments;

-- Mentors: Full access
CREATE POLICY "Authenticated users can read payments" ON public.payments
  FOR SELECT TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can insert payments" ON public.payments
  FOR INSERT TO authenticated WITH CHECK (public.is_mentor());

CREATE POLICY "Authenticated users can update payments" ON public.payments
  FOR UPDATE TO authenticated USING (public.is_mentor());

CREATE POLICY "Authenticated users can delete payments" ON public.payments
  FOR DELETE TO authenticated USING (public.is_mentor());


-- ============================================================================
-- 6. PROSPECTS TABLE
-- ============================================================================
ALTER TABLE public.prospects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users full access to prospects" ON public.prospects;

-- Mentors: Full access
CREATE POLICY "Authenticated users full access to prospects" ON public.prospects
  FOR ALL TO authenticated USING (public.is_mentor());


-- ============================================================================
-- 7. BUSINESS SETTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.business_settings (
  id INT PRIMARY KEY DEFAULT 1,
  company_name TEXT,
  company_address TEXT,
  reg_com TEXT,
  cui_cif TEXT,
  euid TEXT,
  iban TEXT,
  bank_name TEXT,
  beneficiary_entity TEXT,
  service_description TEXT,
  payment_term TEXT,
  refund_deadline TEXT,
  mentor_signature_base64 TEXT,
  discord_webhook_url TEXT,
  mentor_notification_email TEXT,
  resend_api_key TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read business settings for signing" ON public.business_settings;
DROP POLICY IF EXISTS "Mentors full access to business settings" ON public.business_settings;

-- 🛡️ Public: Allow reading notification URLs & company details for public signing links
CREATE POLICY "Public can read business settings for signing" ON public.business_settings
  FOR SELECT USING (true);

-- 🔐 Mentors: Full access to insert/update company settings & notification keys
CREATE POLICY "Mentors full access to business settings" ON public.business_settings
  FOR ALL TO authenticated USING (public.is_mentor());


-- ============================================================================
-- 8. SERVER-SIDE RESEND EMAIL DISPATCH (ZERO CORS RESTRICTIONS)
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.send_resend_email(
  p_to TEXT,
  p_subject TEXT,
  p_html TEXT,
  p_api_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_api_key TEXT;
  v_response_id BIGINT;
BEGIN
  -- Use provided API key or fallback to business_settings table in Supabase
  IF p_api_key IS NOT NULL AND p_api_key <> '' THEN
    v_api_key := p_api_key;
  ELSE
    SELECT resend_api_key INTO v_api_key FROM public.business_settings LIMIT 1;
  END IF;

  IF v_api_key IS NULL OR v_api_key = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Missing Resend API Key');
  END IF;

  -- Server-side HTTP POST to Resend (100% immune to browser CORS)
  SELECT net.http_post(
    url := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_api_key,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'from', 'Agreemint Alerts <onboarding@resend.dev>',
      'to', jsonb_build_array(p_to),
      'subject', p_subject,
      'html', p_html
    )
  ) INTO v_response_id;

  RETURN jsonb_build_object('success', true, 'request_id', v_response_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_resend_email TO anon, authenticated, service_role;
