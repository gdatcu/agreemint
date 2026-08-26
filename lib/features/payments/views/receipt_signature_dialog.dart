import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../settings/services/business_settings_service.dart';

class ReceiptSignatureDialog extends StatefulWidget {
  const ReceiptSignatureDialog({super.key});

  @override
  State<ReceiptSignatureDialog> createState() => _ReceiptSignatureDialogState();
}

class _ReceiptSignatureDialogState extends State<ReceiptSignatureDialog> {
  late final SignatureController _controller;
  Uint8List? _savedMentorSignatureBytes;
  bool _usingSavedSignature = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.indigo.shade900,
      exportBackgroundColor: Colors.transparent,
    );

    _controller.addListener(() {
      if (_controller.isNotEmpty && _usingSavedSignature) {
        setState(() {
          _usingSavedSignature = false;
        });
      }
    });

    _loadSavedSignature();
  }

  Future<void> _loadSavedSignature() async {
    final settings = await BusinessSettingsService.loadSettings();
    if (mounted &&
        settings.mentorSignatureBytes != null &&
        settings.mentorSignatureBytes!.isNotEmpty) {
      setState(() {
        _savedMentorSignatureBytes = settings.mentorSignatureBytes;
        _usingSavedSignature = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    Uint8List? bytes;
    if (_controller.isNotEmpty && !_usingSavedSignature) {
      bytes = await _controller.toPngBytes();
    }

    if (_usingSavedSignature || bytes == null || bytes.isEmpty) {
      bytes ??= _savedMentorSignatureBytes;
    }

    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vă rugăm să semnați înainte de confirmare.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSavedActive = _usingSavedSignature && _savedMentorSignatureBytes != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.draw_outlined,
                        color: Colors.indigo.shade800,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Semnătură Mentor / Signature',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Profile Signature Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSavedActive
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSavedActive
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSavedActive
                        ? Icons.verified_rounded
                        : Icons.edit_note_rounded,
                    color: isSavedActive
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSavedActive
                          ? '✓ Semnătura salvată din Profil este activă'
                          : '✏️ Desenați o semnătură nouă sau folosiți semnătura salvată',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSavedActive
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Signature Pad / Saved Image Box
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade200, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Signature(
                        controller: _controller,
                        height: 180,
                        width: double.infinity,
                        backgroundColor: Colors.white,
                      ),
                      if (isSavedActive && _controller.isEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: Image.memory(
                                  _savedMentorSignatureBytes!,
                                  fit: BoxFit.contain,
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
            const SizedBox(height: 16),

            // Actions Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _usingSavedSignature = false;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Șterge / Clear'),
                    ),
                    if (_savedMentorSignatureBytes != null && !_usingSavedSignature) ...[
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _usingSavedSignature = true;
                          });
                        },
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restabilește Semnătura din Profil', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aplică / Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
