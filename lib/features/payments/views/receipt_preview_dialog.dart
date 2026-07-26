import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'receipt_signature_dialog.dart';

class ReceiptPreviewDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String filename;
  final String title;
  final bool isSigned;
  final Future<Uint8List> Function(Uint8List signatureBytes)? onSignReceipt;

  const ReceiptPreviewDialog({
    super.key,
    required this.pdfBytes,
    required this.filename,
    this.title = 'Chitanță Plată / Payment Receipt',
    this.isSigned = false,
    this.onSignReceipt,
  });

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  late Uint8List _currentPdfBytes;
  late bool _isSignedState;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _currentPdfBytes = widget.pdfBytes;
    _isSignedState = widget.isSigned;
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        await Printing.sharePdf(bytes: _currentPdfBytes, filename: widget.filename);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.filename}');
        await file.writeAsBytes(_currentPdfBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: widget.title,
          text: 'Payment receipt generated via Agreemint.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSignaturePad(BuildContext context) async {
    if (_isSignedState) return;

    final signatureBytes = await showDialog<Uint8List?>(
      context: context,
      builder: (context) => const ReceiptSignatureDialog(),
    );

    if (signatureBytes != null && widget.onSignReceipt != null) {
      setState(() {
        _isSigning = true;
      });

      try {
        final updatedBytes = await widget.onSignReceipt!(signatureBytes);
        if (mounted) {
          setState(() {
            _currentPdfBytes = updatedBytes;
            _isSignedState = true;
            _isSigning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Semnătura a fost aplicată cu succes pe chitanță!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSigning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing receipt: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 800,
          height: 650,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 1,
              actions: [
                if (_isSignedState)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Semnat / Signed',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (widget.onSignReceipt != null)
                  ElevatedButton.icon(
                    onPressed: _isSigning ? null : () => _openSignaturePad(context),
                    icon: const Icon(Icons.draw_outlined, size: 18),
                    label: const Text('Semnează / Sign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Receipt',
                  onPressed: () => _sharePdf(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSigning ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: Stack(
              children: [
                PdfPreview(
                  key: ValueKey(_currentPdfBytes.hashCode),
                  build: (PdfPageFormat format) async => _currentPdfBytes,
                  pdfFileName: widget.filename,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
                if (_isSigning)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Applying signature & saving receipt...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
