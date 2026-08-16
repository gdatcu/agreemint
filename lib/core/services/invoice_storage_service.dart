import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceStorageService {
  static const String _bucketName = 'invoices';

  /// Picks a PDF file from the device and uploads it to Supabase Storage.
  /// Returns the public URL of the uploaded invoice PDF, or null if cancelled/failed.
  static Future<Map<String, String>?> pickAndUploadSoloInvoice({
    required BuildContext context,
    required String paymentId,
    String? invoiceNumberHint,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read PDF bytes. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      final fileName =
          'solo_invoice_${paymentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final supabase = Supabase.instance.client;

      // Upload PDF bytes to 'invoices' bucket
      await supabase.storage.from(_bucketName).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl =
          supabase.storage.from(_bucketName).getPublicUrl(fileName);

      final invoiceNum = (invoiceNumberHint != null && invoiceNumberHint.trim().isNotEmpty)
          ? invoiceNumberHint.trim()
          : 'SOLO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Update payments table with invoice details
      await supabase.from('payments').update({
        'external_invoice_number': invoiceNum,
        'external_invoice_url': publicUrl,
      }).eq('id', paymentId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 Factura SOLO #$invoiceNum s-a încărcat cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return {
        'invoiceNumber': invoiceNum,
        'invoiceUrl': publicUrl,
      };
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcarea facturii: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return null;
    }
  }
}
