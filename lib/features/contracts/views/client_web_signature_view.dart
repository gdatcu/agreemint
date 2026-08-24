import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import '../services/pdf_generator_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/discord_notification_service.dart';
import '../../settings/controllers/business_settings_controller.dart';
import '../../settings/services/business_settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientWebSignatureView extends ConsumerStatefulWidget {
  final String contractId;

  const ClientWebSignatureView({super.key, required this.contractId});

  @override
  ConsumerState<ClientWebSignatureView> createState() =>
      _ClientWebSignatureViewState();
}

class _ClientWebSignatureViewState
    extends ConsumerState<ClientWebSignatureView> {
  late final SignatureController _signatureController;
  final _pdfService = PdfGeneratorService();
  bool _isSubmitting = false;
  ContractModel? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  // Email & OTP verification gate
  bool _isEmailVerified = false;
  bool _otpSent = false;
  final _emailVerifyController = TextEditingController();
  final _phoneVerifyController = TextEditingController();
  final _otpController = TextEditingController();
  String? _emailVerifyError;
  int _emailVerifyAttempts = 0;
  static const int _maxEmailAttempts = 5;
  String? _generatedOtp;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue.shade900,
      exportBackgroundColor: Colors.white,
    );
    _loadContract();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _emailVerifyController.dispose();
    _phoneVerifyController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _computeSecurityOtp() {
    final contractId = widget.contractId;
    final phone = _contract?.enrollment?.student?.phone ?? '0000';
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final last4 = digitsOnly.length >= 4 ? digitsOnly.substring(digitsOnly.length - 4) : '5325';
    final hashSum = contractId.codeUnits.fold(0, (prev, element) => prev + element);
    final twoDigits = (hashSum % 90 + 10).toString();
    return '$last4$twoDigits';
  }

  Future<void> _verifyEmailAndSendOtp() async {
    if (_emailVerifyAttempts >= _maxEmailAttempts) {
      setState(() {
        _emailVerifyError =
            'Prea multe încercări eșuate. Te rugăm să contactezi mentorul pentru asistență.';
      });
      return;
    }

    final enteredEmail = _emailVerifyController.text.trim().toLowerCase();
    final studentEmail = _contract?.enrollment?.student?.email
        .trim()
        .toLowerCase();
    final enteredPhoneLast4 = _phoneVerifyController.text.trim().replaceAll(RegExp(r'\D'), '');

    final rawPhone = _contract?.details?['telefon_cursant'] as String? ?? _contract?.enrollment?.student?.phone ?? '';
    final studentPhoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final expectedLast4 = studentPhoneDigits.length >= 4 ? studentPhoneDigits.substring(studentPhoneDigits.length - 4) : '';

    if (enteredEmail.isEmpty) {
      setState(() {
        _emailVerifyError = 'Te rugăm să introduci adresa ta de email.';
      });
      return;
    }

    if (expectedLast4.isNotEmpty) {
      if (enteredPhoneLast4.isEmpty || enteredPhoneLast4.length < 4) {
        setState(() {
          _emailVerifyError = 'Te rugăm să introduci ultimele 4 cifre ale numărului tău de telefon.';
        });
        return;
      }
      if (enteredPhoneLast4 != expectedLast4) {
        _emailVerifyAttempts++;
        setState(() {
          _emailVerifyError =
              'Ultimele 4 cifre ale telefonului nu corespund dosarului. ${_maxEmailAttempts - _emailVerifyAttempts} încercări rămase.';
        });
        return;
      }
    }

    if (studentEmail != null && studentEmail.isNotEmpty && enteredEmail != studentEmail) {
      _emailVerifyAttempts++;
      setState(() {
        _emailVerifyError =
            'Adresa de email nu corespunde dosarului de cursant. ${_maxEmailAttempts - _emailVerifyAttempts} încercări rămase.';
      });
      return;
    }

    final studentName = _contract?.enrollment?.student?.name ?? 'Beneficiar';

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOtp(
        email: enteredEmail,
        shouldCreateUser: true,
        data: {
          'name': studentName,
        },
      );

      setState(() {
        _otpSent = true;
        _emailVerifyError = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📬 Codul OTP de securitate a fost trimis la $enteredEmail!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _emailVerifyError = 'Nu s-a putut trimite email-ul OTP. Te rugăm să încerci din nou.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtpCode() async {
    final enteredOtp = _otpController.text.trim();
    final enteredEmail = _emailVerifyController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Try verifying as magiclink (for returning/already registered users)
      AuthResponse response;
      try {
        response = await supabase.auth.verifyOTP(
          email: enteredEmail,
          token: enteredOtp,
          type: OtpType.magiclink,
        );
      } catch (_) {
        // Fallback to signup type (for new/first-time users)
        response = await supabase.auth.verifyOTP(
          email: enteredEmail,
          token: enteredOtp,
          type: OtpType.signup,
        );
      }

      if (response.user != null) {
        setState(() {
          _isEmailVerified = true;
          _emailVerifyError = null;
        });
      } else {
        throw Exception('Verification failed');
      }
    } catch (e) {
      _emailVerifyAttempts++;
      setState(() {
        _emailVerifyError =
            'Cod OTP incorect sau expirat. ${_maxEmailAttempts - _emailVerifyAttempts} încercări rămase.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(contractRepositoryProvider);
      final contract = await repo.fetchContractById(widget.contractId);

      if (contract == null) {
        setState(() {
          _errorMessage = 'Contract not found. Please verify your link.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _contract = contract;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contract: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _viewPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open PDF: $url')),
          );
        }
      }
    }
  }

  Future<void> _submitClientSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final clientSigPngBytes = await _signatureController.toPngBytes();
      if (clientSigPngBytes == null) {
        throw Exception('Failed to export signature drawing.');
      }

      final repo = ref.read(contractRepositoryProvider);
      final currentContract = _contract;
      if (currentContract == null) {
        throw Exception('Contract state is missing.');
      }

      // 1. Fetch mentor signature PNG bytes stored from step 1
      final mentorSigBytes = await repo.fetchMentorSignatureBytes(currentContract.enrollmentId);

      // 2. Upload client signature PNG image
      final clientSigUrl = await repo.uploadClientSignature(
        contractId: currentContract.id,
        enrollmentId: currentContract.enrollmentId,
        signatureBytes: clientSigPngBytes,
      );

      final student = currentContract.enrollment?.student;
      final program = currentContract.enrollment?.program;
      final d = currentContract.details ?? {};

      // 3. Generate Version 2 PDF with BOTH mentor and client signatures using exact terms
      final pdfBytes = await _pdfService.generateContractPdf(
        contractNumber: (d['contract_number'] ?? currentContract.contractNumber).toString(),
        date: currentContract.signedDate ?? DateTime.now(),
        studentName: d['student_name'] as String? ?? student?.name ?? 'Beneficiar Program Mentorat',
        adresaCursant: d['adresa_cursant'] as String? ?? '',
        cnpCursant: d['cnp_cursant'] as String? ?? '',
        serieNrCi: d['serie_nr_ci'] as String? ?? '',
        eliberatorCi: d['eliberator_ci'] as String? ?? '',
        dataEliberariiCi: d['data_eliberarii_ci'] as String? ?? '',
        emailCursant: d['email_cursant'] as String? ?? student?.email ?? '',
        telefonCursant: d['telefon_cursant'] as String? ?? student?.phone ?? '',
        clientType: d['client_type'] as String? ?? student?.clientType ?? 'PF',
        cuiCursant: d['cui_cursant'] as String? ?? student?.cui,
        regComCursant: d['reg_com_cursant'] as String? ?? student?.regCom,
        billingAddressCursant: d['billing_address_cursant'] as String? ?? student?.billingAddress,
        programName: d['program_name'] as String? ?? program?.name ?? 'Program Mentorat Tehnic',
        editionName: d['edition_name'] as String? ?? 'Ediția pilot',
        durataOre: (d['durata_ore'] as num?)?.toInt() ?? 40,
        nrSesiuni: (d['nr_sesiuni'] as num?)?.toInt() ?? 20,
        dataIncepere: d['data_incepere'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
        frecventa: d['frecventa'] as String? ?? '1 sesiune pe săptămână',
        priceRon: (d['price_ron'] as num?)?.toDouble() ?? currentContract.priceRon ?? program?.totalPrice ?? 0.0,
        priceLitere: d['price_litere'] as String? ?? '',
        modalitatePlata: d['modalitate_plata'] as String? ?? 'integral, într-o singură tranșă',
        prestatorNume: d['prestator_nume'] as String? ?? 'DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ',
        prestatorSediu: d['prestator_sediu'] as String? ?? 'Bucureşti Sectorul 1, Bulevardul BUCUREŞTII NOI, Nr. 136, Etaj PARTER, Ap. 5',
        prestatorRegCom: d['prestator_reg_com'] as String? ?? 'F2026003426005',
        prestatorCif: d['prestator_cif'] as String? ?? '53430793',
        prestatorEuid: d['prestator_euid'] as String? ?? 'ROONRC.F2026003426005',
        prestatorIban: d['prestator_iban'] as String? ?? 'RO54ROIN4021Q3YWTH1KTUTH',
        prestatorBanca: d['prestator_banca'] as String? ?? 'Salt Bank',
        technologiesCurriculum: d['technologies_curriculum'] as String?,
        beneficiaryEntity: d['beneficiary_entity'] as String?,
        serviceDescription: d['service_description'] as String?,
        paymentTerm: d['payment_term'] as String?,
        refundDeadline: d['refund_deadline'] as String?,
        mentorSignatureBytes: mentorSigBytes,
        clientSignatureBytes: clientSigPngBytes,
      );

      // 3. Upload Version 2 PDF and update signed PDF URL
      await repo.uploadSignedContractPdf(
        contractId: currentContract.id,
        enrollmentId: currentContract.enrollmentId,
        pdfBytes: pdfBytes,
      );

      // 4. Mark status as FullySigned in Supabase
      final updatedContract = await repo.updateStatus(
        contractId: currentContract.id,
        status: 'FullySigned',
        clientSignatureUrl: clientSigUrl,
        clientSignedDate: DateTime.now(),
      );

      // 5. Dispatch Realtime Alerts (Discord + Email) to Mentor in parallel
      try {
        final settings = await BusinessSettingsService.loadSettings();
        final studentNameStr = d['student_name'] as String? ?? student?.name ?? 'Cursant';
        final studentCnpStr = d['cnp_cursant'] as String? ?? student?.cui ?? '';
        final programNameStr = d['program_name'] as String? ?? program?.name ?? 'Program Mentorat';
        final pdfUrlStr = updatedContract.signedPdfUrl ?? updatedContract.pdfUrl ?? '';

        await Future.wait([
          // 1. Dispatch Discord Webhook
          Future(() async {
            try {
              if (settings.discordWebhookUrl != null && settings.discordWebhookUrl!.isNotEmpty) {
                await DiscordNotificationService.notifyContractSigned(
                  webhookUrl: settings.discordWebhookUrl!,
                  studentName: studentNameStr,
                  studentCnp: studentCnpStr,
                  programName: programNameStr,
                  contractNumber: updatedContract.contractNumber,
                  signedPdfUrl: pdfUrlStr,
                );
              }
            } catch (e) {
              debugPrint('Discord Webhook alert error: $e');
            }
          }),
          // 2. Dispatch Email Alert
          Future(() async {
            try {
              if (settings.mentorNotificationEmail != null && settings.mentorNotificationEmail!.isNotEmpty) {
                await EmailService.sendContractSignedEmailAlert(
                  mentorEmail: settings.mentorNotificationEmail!,
                  studentName: studentNameStr,
                  studentCnp: studentCnpStr,
                  programName: programNameStr,
                  contractNumber: updatedContract.contractNumber,
                  signedPdfUrl: pdfUrlStr,
                  resendApiKey: settings.resendApiKey,
                );
              }
            } catch (e) {
              debugPrint('Email alert error: $e');
            }
          }),
        ]);
      } catch (e) {
        debugPrint('Realtime notification trigger failed: $e');
      }

      setState(() {
        _contract = updatedContract;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contract signed and executed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QualiAdept — Client Contract Signing'),
        centerTitle: true,
      ),
      body: SelectionArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadContract,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _contract != null && !_isEmailVerified
                  ? _buildEmailVerificationGate(theme)
                  : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Card
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.school,
                                          size: 32, color: Colors.blue),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Mentorship Agreement Review & Sign',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Contract Nr. ${_contract?.contractNumber ?? 0}',
                                              style:
                                                  theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // State Branching
                          if (_contract?.status == 'FullySigned') ...[
                            // Success State
                            Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.verified,
                                        size: 72, color: Colors.green),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Contract Fully Executed!',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Both parties have signed this agreement. A copy has been generated for your records.',
                                      style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.green.shade900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    if (_contract?.signedPdfUrl != null ||
                                        _contract?.pdfUrl != null)
                                      ElevatedButton.icon(
                                        onPressed: () => _viewPdf(
                                            _contract?.signedPdfUrl ??
                                                _contract?.pdfUrl ??
                                                ''),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                        ),
                                        icon: const Icon(Icons.download),
                                        label: const Text(
                                            'Descarcă Contract Semnat (PDF)'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Invoices & Payment Schedule Card
                            Builder(
                              builder: (context) {
                                final payments = _contract?.enrollment?.payments ?? [];
                                final currency = _contract?.enrollment?.program?.currency ?? 'RON';

                                return Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.receipt_long_rounded,
                                                color: Colors.blue.shade800, size: 28),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Facturi Fiscale & Grafic Tranșe de Plată',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue.shade900,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Consultă tranșele de plată și descarcă facturile fiscale SOLO emise',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 28),
                                        if (payments.isEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Nu au fost configurate încă tranșe de plată pentru acest contract.',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        else
                                          ...payments.asMap().entries.map((entry) {
                                            final idx = entry.key + 1;
                                            final p = entry.value;
                                            final isPaid = p.status == 'Paid';
                                            final hasInvoice = p.externalInvoiceUrl != null && p.externalInvoiceUrl!.trim().isNotEmpty;
                                            final invNumber = p.externalInvoiceNumber;

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isPaid ? Colors.green.shade50 : Colors.blue.shade50.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isPaid ? Colors.green.shade200 : Colors.blue.shade200,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Tranșa #$idx: ${p.amountDue.toStringAsFixed(2)} $currency',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: isPaid ? Colors.green.shade700 : Colors.amber.shade700,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          isPaid ? 'PLĂTIT' : 'ÎN AȘTEPTARE',
                                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Scadență: ${p.dueDate.toIso8601String().split("T")[0]}',
                                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                                  ),
                                                  if (hasInvoice) ...[
                                                    const SizedBox(height: 12),
                                                    ElevatedButton.icon(
                                                      onPressed: () => _viewPdf(p.externalInvoiceUrl!),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green.shade700,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                      ),
                                                      icon: const Icon(Icons.download_rounded, size: 18),
                                                      label: Text('Descarcă Factură Fiscală ${invNumber != null && invNumber.isNotEmpty ? "(SOLO #$invNumber)" : "(SOLO)"}'),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }),
                                        const SizedBox(height: 12),
                                        // Bank details info box
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('🏦 Date Virament Bancar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text('• Beneficiar: ${_contract?.details?['prestator_nume'] ?? 'DATCU GEORGE-CRISTIAN PFA'}', style: const TextStyle(fontSize: 12)),
                                              Text('• IBAN: ${_contract?.details?['prestator_iban'] ?? 'RO54ROIN4021Q3YWTH1KTUTH'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text('• Bancă: ${_contract?.details?['prestator_banca'] ?? 'Salt Bank'}', style: const TextStyle(fontSize: 12)),
                                              Text('• Detalii Plată: Plată mentorat CTR-${_contract?.contractNumber ?? ""} - ${_contract?.details?['student_name'] ?? _contract?.enrollment?.student?.name ?? ""}', style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            // Step 1: Review Mentor Signed Contract Draft PDF
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1. Review Contract Document',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please review the agreement terms signed by your mentor before signing below.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    if (_contract?.pdfUrl != null)
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _viewPdf(_contract!.pdfUrl!),
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text(
                                            'Open & Read Draft Contract (PDF)'),
                                      )
                                    else
                                      const Text(
                                        'Draft PDF is processing...',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Step 2: Draw Signature & Accept
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '2. Draw Your Signature',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Use your finger, mouse, or stylus to sign inside the box below:',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Container(
                                        height: 220,
                                        color: Colors.white,
                                        child: Signature(
                                          controller: _signatureController,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _signatureController.clear(),
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Clear Signature'),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submitClientSignature,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade800,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 14),
                                          ),
                                          icon: _isSubmitting
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white),
                                                )
                                              : const Icon(Icons.check_circle),
                                          label: const Text(
                                              'Sign & Accept Contract'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildEmailVerificationGate(ThemeData theme) {
    final clientName = (_contract?.details?['student_name'] as String?)?.trim() ??
        _contract?.enrollment?.student?.name.trim();
    final greetingSuffix = (clientName != null && clientName.isNotEmpty) ? ', $clientName' : '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome & Guidance Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '👋 Bine ai venit în comunitatea QualiAdept$greetingSuffix!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ne bucurăm că ai decis să colaborezi cu noi pentru dezvoltarea ta profesională! Pentru a revizui și aplica semnătura ta pe contractul de servicii de mentorat, te rugăm mai întâi să confirmi adresa ta de email de mai jos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _otpSent ? Icons.lock_clock_outlined : Icons.verified_user_outlined,
                      size: 48,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _otpSent ? 'Secured OTP Verification' : 'Identity Verification',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _otpSent
                        ? 'Un cod de securitate OTP din 6 cifre a fost generat pentru adresa ${_emailVerifyController.text.trim()}. Introduceți codul mai jos pentru a accesa și semna contractul.'
                        : 'Pentru a accesa și semna contractul, vă rugăm să confirmați adresa de email asociată înscrierii.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!_otpSent) ...[
                    TextField(
                      controller: _emailVerifyController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Adresa ta de Email / Your Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneVerifyController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: 'Ultimele 4 cifre ale nr. de telefon (PIN)',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                        border: const OutlineInputBorder(),
                        counterText: '',
                        errorText: _emailVerifyError,
                        hintText: 'ex: 5225',
                      ),
                      onSubmitted: (_) => _verifyEmailAndSendOtp(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _emailVerifyAttempts >= _maxEmailAttempts
                            ? null
                            : _verifyEmailAndSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Generare & Solicitare Cod OTP'),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Cod Securitate OTP (6 Cifre)',
                        prefixIcon: const Icon(Icons.security_rounded),
                        border: const OutlineInputBorder(),
                        errorText: _emailVerifyError,
                      ),
                      onSubmitted: (_) => _verifyOtpCode(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _emailVerifyAttempts >= _maxEmailAttempts
                            ? null
                            : _verifyOtpCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Validare Cod OTP & Deschidere Contract'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
