import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../students/models/enrollment_model.dart';
import '../../payments/controllers/payment_controller.dart';
import '../controllers/contract_controller.dart';
import '../models/contract_model.dart';
import '../../../core/constants.dart';
import '../../../core/services/frankfurter_service.dart';

class ContractSigningView extends ConsumerStatefulWidget {
  final EnrollmentModel enrollment;

  const ContractSigningView({super.key, required this.enrollment});

  @override
  ConsumerState<ContractSigningView> createState() =>
      _ContractSigningViewState();
}

class _ContractSigningViewState extends ConsumerState<ContractSigningView> {
  late final SignatureController _signatureController;
  bool _isGenerating = false;

  final _formKey = GlobalKey<FormState>();
  final _adresaController = TextEditingController();
  final _cnpController = TextEditingController();
  final _serieNrCiController = TextEditingController();
  final _eliberatorCiController = TextEditingController();
  final _dataEliberariiCiController = TextEditingController();
  final _editionNameController = TextEditingController(text: 'Ediția pilot');
  final _durataOreController = TextEditingController(text: '40');
  final _nrSesiuniController = TextEditingController(text: '20');
  final _dataIncepereController = TextEditingController();
  final _frecventaController =
      TextEditingController(text: '1 sesiune pe săptămână');
  final _priceLitereController = TextEditingController();
  final _modalitatePlataController =
      TextEditingController(text: 'integral, într-o singură tranșă');

  // Prestator profile fields controllers (default preset values)
  final _prestatorNumeController = TextEditingController(
      text: 'DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ');
  final _prestatorSediuController = TextEditingController(
      text:
          'Bucureşti Sectorul 1, Bulevardul BUCUREŞTII NOI, Nr. 136, Etaj PARTER, Ap. 5');
  final _prestatorRegComController =
      TextEditingController(text: 'F2026003426005');
  final _prestatorCifController = TextEditingController(text: '53430793');
  final _prestatorIbanController =
      TextEditingController(text: 'RO54ROIN4021Q3YWTH1KTUTH');
  final _prestatorBancaController = TextEditingController(text: 'Salt Bank');

  // Expanded bilingual contract parameters controllers
  late final TextEditingController _technologiesController;
  final _beneficiaryEntityController =
      TextEditingController(text: 'QualiAdept Community');
  final _serviceDescriptionController = TextEditingController(
      text:
          'sesiuni live online, feedback pe cod (code review) și consultanță');
  final _paymentTermController =
      TextEditingController(text: '3 (trei) zile calendaristice');
  final _refundDeadlineController =
      TextEditingController(text: '5 (cinci) zile calendaristice');

  late final TextEditingController _priceRonController;
  late final TextEditingController _contractNumberController;
  double? _liveRate;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue.shade900,
      exportBackgroundColor: Colors.white,
    );
    _dataIncepereController.text =
        DateTime.now().toIso8601String().split('T')[0];

    final program = widget.enrollment.program;
    final initialPrice = program?.totalPrice ?? 1000.00;
    _priceRonController =
        TextEditingController(text: initialPrice.toStringAsFixed(2));
    _contractNumberController = TextEditingController();

    if (program != null && program.currency == 'EUR') {
      _fetchLiveRateAndConvert(program.totalPrice);
    }

    final techCurriculum = (program?.description != null &&
            program!.description!.trim().isNotEmpty)
        ? program.description!.trim()
        : (program?.name != null && program!.name.isNotEmpty)
            ? program.name
            : 'QA Automation (TS + Playwright)';
    _technologiesController = TextEditingController(text: techCurriculum);
  }

  void _fetchLiveRateAndConvert(double eurPrice) async {
    final rate = await FrankfurterService.getEurToRonRate();
    if (mounted) {
      setState(() {
        _liveRate = rate;
        final convertedRon = eurPrice * rate;
        _priceRonController.text = convertedRon.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _priceRonController.dispose();
    _contractNumberController.dispose();
    _adresaController.dispose();
    _cnpController.dispose();
    _serieNrCiController.dispose();
    _eliberatorCiController.dispose();
    _dataEliberariiCiController.dispose();
    _editionNameController.dispose();
    _durataOreController.dispose();
    _nrSesiuniController.dispose();
    _dataIncepereController.dispose();
    _frecventaController.dispose();
    _priceLitereController.dispose();
    _modalitatePlataController.dispose();

    // Dispose prestator controllers
    _prestatorNumeController.dispose();
    _prestatorSediuController.dispose();
    _prestatorRegComController.dispose();
    _prestatorCifController.dispose();
    _prestatorIbanController.dispose();
    _prestatorBancaController.dispose();

    _technologiesController.dispose();
    _beneficiaryEntityController.dispose();
    _serviceDescriptionController.dispose();
    _paymentTermController.dispose();
    _refundDeadlineController.dispose();
    super.dispose();
  }

  Future<void> _shareContractLink(String contractId) async {
    final link = '${AppConstants.clientPortalBaseUrl}$contractId';
    await Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing link copied to clipboard!\n$link'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'SHARE',
            onPressed: () {
              Share.share(
                'Hi! Please review and sign your mentoring program contract here: $link',
                subject: 'Mentorship Agreement Contract Signing',
              );
            },
          ),
        ),
      );
    }

    try {
      await Share.share(
        'Hi! Please review and sign your mentoring program contract here: $link',
        subject: 'Mentorship Agreement Contract Signing',
      );
    } catch (_) {
      // Fallback silently if platform share isn't supported
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

  Future<void> _signAndGenerateContract() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final student = widget.enrollment.student;
    final program = widget.enrollment.program;

    if (student == null || program == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to generate contract: Student or Program data is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool updateSequenceBase = true;
    final customNum = int.tryParse(_contractNumberController.text.trim());
    if (customNum != null && customNum > 0) {
      final choice = await _showSequenceOptionDialog(context, customNum);
      if (choice == null) return; // User dismissed
      updateSequenceBase = choice;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final pngBytes = await _signatureController.toPngBytes();
      if (pngBytes == null) {
        throw Exception('Failed to export signature image.');
      }

      final notifier = ref.read(
          enrollmentContractControllerProvider(widget.enrollment.id).notifier);

      await notifier.issueContract(
        studentName: student.name,
        adresaCursant: _adresaController.text.trim(),
        cnpCursant: _cnpController.text.trim(),
        serieNrCi: _serieNrCiController.text.trim(),
        eliberatorCi: _eliberatorCiController.text.trim(),
        dataEliberariiCi: _dataEliberariiCiController.text.trim(),
        emailCursant: student.email,
        telefonCursant: student.phone ?? '',
        programName: program.name,
        editionName: _editionNameController.text.trim(),
        durataOre: int.parse(_durataOreController.text.trim()),
        nrSesiuni: int.parse(_nrSesiuniController.text.trim()),
        dataIncepere: _dataIncepereController.text.trim(),
        frecventa: _frecventaController.text.trim(),
        priceRon: double.tryParse(_priceRonController.text.trim()) ?? program.totalPrice,
        priceLitere: _priceLitereController.text.trim(),
        modalitatePlata: _modalitatePlataController.text.trim(),
        prestatorNume: _prestatorNumeController.text.trim(),
        prestatorSediu: _prestatorSediuController.text.trim(),
        prestatorRegCom: _prestatorRegComController.text.trim(),
        prestatorCif: _prestatorCifController.text.trim(),
        prestatorIban: _prestatorIbanController.text.trim(),
        prestatorBanca: _prestatorBancaController.text.trim(),
        technologiesCurriculum: _technologiesController.text.trim(),
        beneficiaryEntity: _beneficiaryEntityController.text.trim(),
        serviceDescription: _serviceDescriptionController.text.trim(),
        paymentTerm: _paymentTermController.text.trim(),
        refundDeadline: _refundDeadlineController.text.trim(),
        customContractNumber: customNum,
        updateSequenceBase: updateSequenceBase,
        signatureBytes: pngBytes,
      );

      if (!mounted) return;
      final resultState =
          ref.read(enrollmentContractControllerProvider(widget.enrollment.id));
      if (resultState is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${resultState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Contract issued by mentor! Send the signing link to your client.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadSignedContract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        throw Exception('Could not read file bytes.');
      }

      setState(() {
        _isGenerating = true;
      });

      await ref
          .read(enrollmentContractControllerProvider(widget.enrollment.id)
              .notifier)
          .uploadSignedContract(pdfBytes: bytes);

      if (!mounted) return;
      final resultState =
          ref.read(enrollmentContractControllerProvider(widget.enrollment.id));
      if (resultState is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${resultState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed contract uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(enrollmentContractControllerProvider(widget.enrollment.id),
        (previous, next) {
      final contract = next.valueOrNull;
      if (contract != null) {
        if (contract.priceRon != null) {
          final formattedPrice = contract.priceRon!.toStringAsFixed(2);
          if (_priceRonController.text != formattedPrice) {
            _priceRonController.text = formattedPrice;
          }
        }
        if (contract.contractNumber > 0 && _contractNumberController.text.isEmpty) {
          _contractNumberController.text = contract.contractNumber.toString();
        }
      }
    });

    final contractAsync =
        ref.watch(enrollmentContractControllerProvider(widget.enrollment.id));
    final paymentsAsync =
        ref.watch(enrollmentPaymentsControllerProvider(widget.enrollment.id));
    final student = widget.enrollment.student;
    final program = widget.enrollment.program;
    final contract = contractAsync.valueOrNull;

    // Calculate total settled payment amount for this enrollment if payments exist
    double? totalPaymentsAmount;
    final payments = paymentsAsync.valueOrNull;
    if (payments != null && payments.isNotEmpty) {
      totalPaymentsAmount = payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amountDue,
      );
    }

    final displayPrice = contract?.priceRon ??
        totalPaymentsAmount ??
        (double.tryParse(_priceRonController.text) ??
            program?.totalPrice ??
            1000.00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Management'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (program != null) ...[
                  Card(
                    child: ListTile(
                      title: Text(program.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Mentorship Price: ${displayPrice.toStringAsFixed(2)} RON'),
                      leading: const Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (student != null) ...[
                  Card(
                    child: ListTile(
                      title: Text(student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${student.email} | ${student.phone ?? "No phone"}'),
                      leading: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                contractAsync.when(
                  data: (contract) {
                    if (contract != null && contract.status != 'Draft') {
                      return _buildContractStatusCard(context, contract);
                    }
                    return _buildContractForm(context, student, program);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) =>
                      _buildContractForm(context, student, program),
                ),
              ],
            ),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing Contract...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractStatusCard(
      BuildContext context, ContractModel contract) {
    final theme = Theme.of(context);
    final isFullySigned = contract.status == 'FullySigned';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFullySigned) ...[
          // Fully Signed Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 36, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fully Signed by Both Parties',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Client Signed Date: ${contract.clientSignedDate?.toLocal().toString().split(' ')[0] ?? contract.signedDate?.toLocal().toString().split(' ')[0] ?? "Signed"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (contract.signedPdfUrl != null ||
                          contract.pdfUrl != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _viewPdf(contract.signedPdfUrl ??
                                contract.pdfUrl ??
                                ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('View/Share Final Contract'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Pending Client Signature Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          size: 36, color: Colors.orange.shade900),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waiting for Client Signature',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mentor signature submitted. Please share the portal link with your student.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _shareContractLink(contract.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Client for Signature'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (contract.pdfUrl != null)
                        OutlinedButton.icon(
                          onPressed: () => _viewPdf(contract.pdfUrl!),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View Draft PDF'),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickAndUploadSignedContract,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Signed PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContractForm(
      BuildContext context, dynamic student, dynamic program) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PART 1: PRESTATOR (PFA DETAILS)
          ExpansionTile(
            title: const Text(
              'Date Prestator (PFA Mentor Info)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: false,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _prestatorNumeController,
                      decoration:
                          const InputDecoration(labelText: 'Nume Prestator'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vă rugăm introduceți numele prestatorului'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _prestatorSediuController,
                      decoration: const InputDecoration(
                          labelText: 'Sediu Profesional'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vă rugăm introduceți sediul'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prestatorCifController,
                            decoration:
                                const InputDecoration(labelText: 'CUI / CIF'),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Introduceți CUI'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _prestatorRegComController,
                            decoration: const InputDecoration(
                                labelText: 'Nr. Reg. Com.'),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Introduceți Reg Com'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prestatorIbanController,
                            decoration:
                                const InputDecoration(labelText: 'Cont IBAN'),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Introduceți IBAN'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _prestatorBancaController,
                            decoration:
                                const InputDecoration(labelText: 'Banca'),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Introduceți banca'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // PART 2: BENEFICIAR
          Text(
            'Required Cursant/Student Information:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adresaController,
            decoration: const InputDecoration(
              labelText: 'Adresă completă din CI',
              hintText: 'ex: Jud. Ilfov, Loc. Chiajna, Str. Tineretului Nr. 12',
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Vă rugăm să introduceți adresa'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cnpController,
            decoration: const InputDecoration(
              labelText: 'CNP Cursant',
              hintText: 'ex: 5010203xxxxxx',
            ),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vă rugăm să introduceți CNP-ul';
              }
              if (val.trim().length != 13 || int.tryParse(val) == null) {
                return 'CNP-ul trebuie să conțină fix 13 cifre';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serieNrCiController,
                  decoration: const InputDecoration(
                    labelText: 'Serie și Nr. CI',
                    hintText: 'ex: RX 123456',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți seria CI'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _eliberatorCiController,
                  decoration: const InputDecoration(
                    labelText: 'Eliberat de',
                    hintText: 'ex: SPCLEP Sector 1',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți emitentul CI'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dataEliberariiCiController,
            decoration: const InputDecoration(
              labelText: 'Data eliberării CI',
              hintText: 'ex: 12.05.2023',
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Introduceți data eliberării CI'
                : null,
          ),
          const SizedBox(height: 24),

          // PART 3: PROGRAM DETAILS
          Text(
            'Course & Financial Schedule Details:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (program?.currency == 'EUR') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_exchange, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _liveRate != null
                          ? 'Frankfurter API Exchange Rate: 1 EUR = ${_liveRate!.toStringAsFixed(4)} RON\nProgram Price: ${program!.totalPrice.toStringAsFixed(2)} EUR → Auto-converted to RON for Legal Contract.'
                          : 'Fetching live EUR → RON exchange rate from Frankfurter API...',
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _editionNameController,
                  decoration: const InputDecoration(
                    labelText: 'Comunitate / Ediție',
                    hintText:
                        'ex: Ediția pilot / Beta Cohort exclusiv pentru QualiAdept',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți ediția programului'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _contractNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nr. Contract (Auto/Manual)',
                    hintText: 'ex: 1',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durataOreController,
                  decoration: const InputDecoration(
                    labelText: 'Durată estimată (ore)',
                    hintText: 'ex: 40',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vă rugăm introduceți durata';
                    }
                    if (int.tryParse(val) == null) {
                      return 'Durata trebuie să fie numerică';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nrSesiuniController,
                  decoration: const InputDecoration(
                    labelText: 'Număr sesiuni',
                    hintText: 'ex: 20',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vă rugăm introduceți numărul de sesiuni';
                    }
                    if (int.tryParse(val) == null) {
                      return 'Sesiunile trebuie să fie numerice';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dataIncepereController,
                  decoration: const InputDecoration(
                    labelText: 'Data începerii',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți data de început'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _frecventaController,
                  decoration: const InputDecoration(
                    labelText: 'Frecvență sesiuni',
                    hintText: 'ex: 1 sesiune pe săptămână',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți frecvența'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceRonController,
                  decoration: const InputDecoration(
                    labelText: 'Preț Total (RON)',
                    hintText: 'ex: 1000.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Introduceți prețul';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Preț invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceLitereController,
                  decoration: const InputDecoration(
                    labelText: 'Preț total în litere',
                    hintText: 'ex: o mie lei',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Introduceți prețul în litere'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _modalitatePlataController,
            decoration: const InputDecoration(
              labelText: 'Modalitate de plată',
              hintText: 'ex: integral / în 2 tranșe egale',
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Introduceți modalitatea de plată'
                : null,
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text(
              'Advanced Contract Terms & Specifications (Bilingual)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Curriculum, Beneficiary Entity, Service Description, Payment Term & Refund Deadline',
              style: TextStyle(fontSize: 12),
            ),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _technologiesController,
                      decoration: const InputDecoration(
                        labelText: 'Tehnologii / Curriculum',
                        hintText: 'ex: QA Automation (TS + Playwrite)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _beneficiaryEntityController,
                      decoration: const InputDecoration(
                        labelText: 'Comunitate / Entitate Beneficiară',
                        hintText: 'ex: QualiAdept Community',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _serviceDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descriere Servicii',
                        hintText: 'ex: sesiuni live online, feedback pe cod și consultanță',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _paymentTermController,
                            decoration: const InputDecoration(
                              labelText: 'Termen de Plată',
                              hintText: 'ex: 3 (trei) zile calendaristice',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _refundDeadlineController,
                            decoration: const InputDecoration(
                              labelText: 'Termen Rambursare',
                              hintText: 'ex: 5 (cinci) zile calendaristice',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // PART 4: MENTOR SIGNATURE
          Text(
            'Semnătura Prestatorului (Mentor Signature):',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 180,
              color: Colors.white,
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _signatureController.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear Canvas'),
              ),
              ElevatedButton.icon(
                onPressed: _signAndGenerateContract,
                icon: const Icon(Icons.draw),
                label: const Text('Generate & Issue Draft Contract'),
              ),
            ],
          ),
          const Divider(height: 48),

          // PART 5: DIRECT UPLOAD ALTERNATIVE
          Text(
            'Or, Skip Generation & Upload Final Signed Contract directly:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickAndUploadSignedContract,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Signed Contract PDF'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<bool?> _showSequenceOptionDialog(
      BuildContext context, int customNum) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.format_list_numbered, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Contract Sequence Preference'),
            ],
          ),
          content: Text(
            'You specified a custom contract number: #$customNum.\n\n'
            'How should future contracts be numbered?',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'One-off Record Only\n(Keep previous sequence)',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Set as New Sequence Base\n(Continue: ${customNum + 1}, ${customNum + 2}...)',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
