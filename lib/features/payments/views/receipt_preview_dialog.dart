import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ReceiptPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String filename;
  final String title;

  const ReceiptPreviewDialog({
    super.key,
    required this.pdfBytes,
    required this.filename,
    this.title = 'Chitanță Plată / Payment Receipt',
  });

  Future<void> _sharePdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: title,
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
              title: Text(title),
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Receipt',
                  onPressed: () => _sharePdf(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: PdfPreview(
              build: (PdfPageFormat format) async => pdfBytes,
              pdfFileName: filename,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ),
      ),
    );
  }
}
