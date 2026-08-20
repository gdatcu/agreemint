-- Run this script inside your Supabase SQL Editor to create the server-side email relay function.
-- Go to: Supabase Dashboard > SQL Editor > New query > Paste this > click Run.

-- Enable HTTP extension if not already enabled
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.send_email_otp(p_email TEXT, p_otp TEXT, p_name TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with high-privilege access so it bypasses RLS
AS $$
DECLARE
  v_response record;
  v_body jsonb;
  v_resend_api_key TEXT := 'YOUR_RESEND_API_KEY_HERE';
  v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
  v_student_exists BOOLEAN;
BEGIN
  -- 🛡️ SECURITY GATE: Verify the email belongs to a real student with an unsigned contract
  SELECT EXISTS (
    SELECT 1 
    FROM public.students s
    JOIN public.enrollments e ON e.student_id = s.id
    JOIN public.contracts c ON c.enrollment_id = e.id
    WHERE LOWER(s.email) = LOWER(p_email) AND c.status IN ('Draft', 'PendingClient')
  ) INTO v_student_exists;

  IF NOT v_student_exists THEN
    RETURN jsonb_build_object(
      'status', 403,
      'error', 'Unauthorized. Email address does not match any pending contracts.'
    );
  END IF;

  -- Construct the transactional email HTML body
  v_body := jsonb_build_object(
    'from', 'QualiAdept <billing@qualiadept.eu>',
    'to', jsonb_build_array(p_email),
    'subject', 'Cod de securitate QualiAdept / Verification Code',
    'html', '<div style="font-family: ''Segoe UI'', Tahoma, Geneva, Verdana, sans-serif; max-width: 550px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff; color: #1e293b;">' ||
            '  <div style="text-align: center; margin-bottom: 24px;">' ||
            '    <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>' ||
            '    <p style="color: #64748b; font-size: 13px; margin: 6px 0 0 0; font-weight: 500; text-transform: uppercase; letter-spacing: 1px;">Secured Contract Verification</p>' ||
            '  </div>' ||
            '  <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />' ||
            '  <p style="font-size: 15px; line-height: 1.6; margin: 0 0 12px 0;">Salut <strong>' || p_name || '</strong>,</p>' ||
            '  <p style="font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">Îți mulțumim pentru înscrierea în programul de mentorat QualiAdept! Pentru a accesa, revizui și semna contractul tău digital de colaborare, folosește codul de securitate OTP de mai jos:</p>' ||
            '  <div style="background-color: #f8fafc; padding: 18px; text-align: center; border-radius: 8px; margin: 24px 0; border: 1px dashed #cbd5e1;">' ||
            '    <span style="font-size: 28px; font-weight: 800; letter-spacing: 6px; color: #0f172a; font-family: monospace;">' || p_otp || '</span>' ||
            '  </div>' ||
            '  <p style="font-size: 12.5px; color: #64748b; line-height: 1.5; margin: 20px 0 0 0; font-style: italic;">Acest cod este confidențial și valid pentru sesiunea curentă. Dacă nu ai solicitat inițierea semnării acestui contract, te rugăm să ignori acest mesaj.</p>' ||
            '  <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 0 0;" />' ||
            '  <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 16px 0 0 0;">DATCU GEORGE-CRISTIAN PFA / QualiAdept © ' || v_current_year || '. Toate drepturile rezervate.</p>' ||
            '</div>'
  );

  -- Perform server-side POST request to Resend API
  SELECT * INTO v_response FROM extensions.http((
    'POST',
    'https://api.resend.com/emails',
    ARRAY[
      extensions.http_header('Authorization', 'Bearer ' || v_resend_api_key),
      extensions.http_header('Content-Type', 'application/json')
    ],
    'application/json',
    v_body::text
  )::extensions.http_request);

  RETURN jsonb_build_object(
    'status', v_response.status,
    'content', v_response.content::jsonb
  );
END;
$$;

-- Grant execution permission to anonymous web users
GRANT EXECUTE ON FUNCTION public.send_email_otp(TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.send_email_otp(TEXT, TEXT, TEXT) TO authenticated;
