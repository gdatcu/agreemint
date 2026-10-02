import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/invoice_smart_link_parser.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';

class SoloInvoiceDialog extends ConsumerStatefulWidget {
  final PaymentModel payment;
  final String enrollmentId;
  final void Function(String invoiceNumber, String? invoiceUrl)? onSaved;

  const SoloInvoiceDialog({
    super.key,
    required this.payment,
    required this.enrollmentId,
    this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required PaymentModel payment,
    required String enrollmentId,
    void Function(String invoiceNumber, String? invoiceUrl)? onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SoloInvoiceDialog(
        payment: payment,
        enrollmentId: enrollmentId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<SoloInvoiceDialog> createState() => _SoloInvoiceDialogState();
}

class _SoloInvoiceDialogState extends ConsumerState<SoloInvoiceDialog> {
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _invoiceUrlController;
  final TextEditingController _smartInputController = TextEditingController();

  ParsedInvoiceResult? _lastParsedResult;
  bool _isUploadingPdf = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController =
        TextEditingController(text: widget.payment.externalInvoiceNumber ?? '');
    _invoiceUrlController =
        TextEditingController(text: widget.payment.externalInvoiceUrl ?? '');

    // Auto-detect if user pastes raw text/links directly into fields
    _invoiceNumberController.addListener(_onNumberFieldChanged);
  }

  @override
  void dispose() {
    _invoiceNumberController.removeListener(_onNumberFieldChanged);
    _invoiceNumberController.dispose();
    _invoiceUrlController.dispose();
    _smartInputController.dispose();
    super.dispose();
  }

  void _onNumberFieldChanged() {
    final text = _invoiceNumberController.text.trim();
    // If user pasted a full URL or sentence into the invoice number field
    if (text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.contains('solo.ro') ||
        text.contains('factur') ||
        text.contains('din data')) {
      final parsed = InvoiceSmartLinkParser.parse(text);
      if (parsed.isValid) {
        if (parsed.invoiceNumber != null && parsed.invoiceNumber != text) {
          _invoiceNumberController.text = parsed.invoiceNumber!;
          _invoiceNumberController.selection = TextSelection.fromPosition(
            TextPosition(offset: _invoiceNumberController.text.length),
          );
        }
        if (parsed.invoiceUrl != null && _invoiceUrlController.text.isEmpty) {
          _invoiceUrlController.text = parsed.invoiceUrl!;
        }
        setState(() {
          _lastParsedResult = parsed;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard-ul este gol.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      _smartInputController.text = text;
      _applySmartParsing(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la citirea clipboard: $e')),
        );
      }
    }
  }

  void _applySmartParsing(String rawText) {
    if (rawText.trim().isEmpty) return;

    final result = InvoiceSmartLinkParser.parse(rawText);
    setState(() {
      _lastParsedResult = result;
    });

    if (result.isValid) {
      if (result.invoiceNumber != null &&
          result.invoiceNumber!.trim().isNotEmpty) {
        _invoiceNumberController.text = result.invoiceNumber!;
      }
      if (result.invoiceUrl != null && result.invoiceUrl!.trim().isNotEmpty) {
        _invoiceUrlController.text = result.invoiceUrl!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✨ Detectat: ${result.invoiceNumber ?? ""} (${result.platform.name.toUpperCase()})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Nu s-a putut extrage un număr sau link de factură din text.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      setState(() => _isUploadingPdf = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final number = _invoiceNumberController.text.trim();
          final invNum = number.isNotEmpty ? number : 'SOLO-PDF';

          final uploadedUrl = await ref
              .read(enrollmentPaymentsControllerProvider(widget.enrollmentId)
                  .notifier)
              .uploadSoloInvoicePdf(
                paymentId: widget.payment.id,
                invoiceNumber: invNum,
                pdfBytes: file.bytes!,
                fileName: file.name,
              );

          _invoiceUrlController.text = uploadedUrl;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('📄 Factura PDF a fost încărcată cu succes în cloud!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPdf = false);
    }
  }

  Future<void> _openInvoiceUrl() async {
    final url = _invoiceUrlController.text.trim();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link-ul facturii nu este valid.')),
          );
        }
      }
    }
  }

  Future<void> _saveInvoice() async {
    final number = _invoiceNumberController.text.trim();
    final url = _invoiceUrlController.text.trim();

    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vă rugăm să introduceți seria și numărul facturii.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(enrollmentPaymentsControllerProvider(widget.enrollmentId)
              .notifier)
          .saveExternalInvoice(
            paymentId: widget.payment.id,
            invoiceNumber: number,
            invoiceUrl: url.isNotEmpty ? url : null,
          );

      widget.onSaved?.call(number, url.isNotEmpty ? url : null);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 Factura #$number a fost salvată cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la salvare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = _invoiceUrlController.text.trim().isNotEmpty;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: Colors.blue.shade800, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factură Fiscală SOLO / Link Parser',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.payment.amountPaid ?? widget.payment.amountDue} ${widget.payment.enrollment?.program?.currency ?? "RON"} • ${widget.payment.status}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Smart Link & Message Parser Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.indigo.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Smart Link & Text Parser',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_paste,
                                    size: 13, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Paste Clipboard',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _smartInputController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText:
                            'Pasează un link SOLO (ex: https://app.solo.ro/invoices/SL-10492) sau mesajul complet de pe WhatsApp...',
                        hintStyle: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.all(8),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size.fromHeight(34),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: const Text(
                              '⚡ Parsează Link / Text',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () =>
                                _applySmartParsing(_smartInputController.text),
                          ),
                        ),
                      ],
                    ),
                    if (_lastParsedResult != null &&
                        _lastParsedResult!.isValid) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Detectat: ${_lastParsedResult!.invoiceNumber ?? "Link valid"} • ${_lastParsedResult!.platform.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                            if (_lastParsedResult!.amount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_lastParsedResult!.amount} ${_lastParsedResult!.currency ?? ""}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Invoice Number Field
              TextField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(
                  labelText: 'Număr Factură SOLO (ex: SL-10492, SOLO-10492) *',
                  hintText: 'ex: SL-10492',
                  prefixIcon: const Icon(Icons.numbers, size: 20),
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Invoice URL Field
              TextField(
                controller: _invoiceUrlController,
                decoration: InputDecoration(
                  labelText: 'Link Factură / URL PDF (Opțional)',
                  hintText: 'https://app.solo.ro/invoices/SL-10492',
                  prefixIcon: const Icon(Icons.link, size: 20),
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: hasUrl
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          tooltip: 'Deschide link-ul în browser',
                          onPressed: _openInvoiceUrl,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 14),

              // 4. File Upload & Quick Open Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isUploadingPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file, size: 16),
                      label: Text(
                        _isUploadingPdf
                            ? 'Se încarcă...'
                            : 'Încarcă PDF Factură',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _isUploadingPdf ? null : _pickAndUploadPdf,
                    ),
                  ),
                  if (hasUrl) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text(
                          'Deschide PDF',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: _openInvoiceUrl,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check, size: 16),
          label: Text(_isSaving ? 'Se salvează...' : 'Salvează Factura'),
          onPressed: _isSaving ? null : _saveInvoice,
        ),
      ],
    );
  }
}
