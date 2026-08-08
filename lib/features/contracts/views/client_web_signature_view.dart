import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import '../services/pdf_generator_service.dart';

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

  // Email verification gate
  bool _isEmailVerified = false;
  final _emailVerifyController = TextEditingController();
  String? _emailVerifyError;
  int _emailVerifyAttempts = 0;
  static const int _maxEmailAttempts = 5;

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
    super.dispose();
  }

  void _verifyEmail() {
    if (_emailVerifyAttempts >= _maxEmailAttempts) {
      setState(() {
        _emailVerifyError =
            'Too many failed attempts. Please contact your mentor for assistance.';
      });
      return;
    }

    final enteredEmail = _emailVerifyController.text.trim().toLowerCase();
    final studentEmail = _contract?.enrollment?.student?.email
        .trim()
        .toLowerCase();

    if (enteredEmail.isEmpty) {
      setState(() {
        _emailVerifyError = 'Please enter your email address.';
      });
      return;
    }

    if (studentEmail == null || studentEmail.isEmpty) {
      // No student email on record — allow access (graceful fallback)
      setState(() {
        _isEmailVerified = true;
      });
      return;
    }

    if (enteredEmail == studentEmail) {
      setState(() {
        _isEmailVerified = true;
        _emailVerifyError = null;
      });
    } else {
      _emailVerifyAttempts++;
      setState(() {
        _emailVerifyError =
            'Email does not match our records. ${_maxEmailAttempts - _emailVerifyAttempts} attempts remaining.';
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
      body: _isLoading
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
                                            'Download Final Signed Contract'),
                                      ),
                                  ],
                                ),
                              ),
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
    );
  }

  Widget _buildEmailVerificationGate(ThemeData theme) {
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 48,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Identity Verification',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To view and sign this contract, please confirm your identity by entering the email address associated with your enrollment.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailVerifyController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Your Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _emailVerifyError,
                    ),
                    onSubmitted: (_) => _verifyEmail(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _emailVerifyAttempts >= _maxEmailAttempts
                          ? null
                          : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Verify & View Contract'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
