import 'package:flutter/material.dart';

class VerifyCertificateView extends StatelessWidget {
  final String certificateId;
  final String studentName;
  final String programName;
  final String issueDate;
  final String courseHours;

  const VerifyCertificateView({
    super.key,
    required this.certificateId,
    required this.studentName,
    required this.programName,
    required this.issueDate,
    required this.courseHours,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = studentName.isNotEmpty ? studentName : 'Absolvent QualiAdept';
    final displayProgram = programName.isNotEmpty ? programName : 'Program Mentorat';
    final displayHours = courseHours.isNotEmpty ? courseHours : '50';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('QualiAdept - Autentificare Certificat'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD97706),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Verification Badge Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade400, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'CERTIFICAT AUTENTIC ȘI VERIFICAT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'OFFICIAL QUALIADEPT VERIFIED CERTIFICATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),

                // Record Details Card
                _buildDetailRow(context, 'Nume Absolvent / Graduate', displayName,
                    isBold: true),
                const SizedBox(height: 12),
                _buildDetailRow(
                    context, 'Program Absolvit / Program', displayProgram),
                const SizedBox(height: 12),
                _buildDetailRow(context, 'Durată Totală / Duration',
                    '$displayHours ore de consultanță live și practică / hours'),
                const SizedBox(height: 12),
                _buildDetailRow(
                    context, 'Cod Certificat / ID', certificateId),
                if (issueDate.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Data Emiterii / Date', issueDate),
                ],
                const SizedBox(height: 12),
                _buildDetailRow(
                    context, 'Emitent / Provider', 'DATCU GEORGE-CRISTIAN PFA / QUALIADEPT'),

                const SizedBox(height: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFD97706).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security,
                          size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Acest certificat a fost generat digital și înregistrat în sistemul oficial QualiAdept Mentorship.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
