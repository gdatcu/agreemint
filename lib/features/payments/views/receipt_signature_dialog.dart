import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class ReceiptSignatureDialog extends StatefulWidget {
  const ReceiptSignatureDialog({super.key});

  @override
  State<ReceiptSignatureDialog> createState() => _ReceiptSignatureDialogState();
}

class _ReceiptSignatureDialogState extends State<ReceiptSignatureDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.indigo.shade900,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vă rugăm să semnați înainte de confirmare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bytes = await _controller.toPngBytes();
    if (mounted) {
      Navigator.of(context).pop(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Semnătură Mentor / Signature',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Desenați semnătura în caseta de mai jos:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade200, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: _controller,
                  height: 180,
                  width: double.infinity,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _controller.clear(),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Șterge / Clear'),
                ),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aplică / Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
