import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class DocGatewayView extends StatefulWidget {
  final String pdfUrl;
  final String expectedPin;
  final String docTitle;

  const DocGatewayView({
    super.key,
    required this.pdfUrl,
    required this.expectedPin,
    required this.docTitle,
  });

  @override
  State<DocGatewayView> createState() => _DocGatewayViewState();
}

class _DocGatewayViewState extends State<DocGatewayView> {
  final TextEditingController _pinController = TextEditingController();
  bool _isUnlocked = false;
  bool _isLoadingPdf = false;
  Uint8List? _pdfBytes;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() async {
    setState(() {
      _errorMessage = null;
    });

    final enteredPin = _pinController.text.trim();
    if (enteredPin != widget.expectedPin) {
      setState(() {
        _errorMessage =
            '❌ PIN incorect. Vă rugăm să introduceți ultimele 4 cifre ale numărului de telefon.';
      });
      return;
    }

    // PIN matched cleanly! Fetch the PDF bytes and render
    setState(() {
      _isLoadingPdf = true;
    });

    try {
      final res = await http.get(Uri.parse(widget.pdfUrl));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        setState(() {
          _pdfBytes = res.bodyBytes;
          _isUnlocked = true;
          _isLoadingPdf = false;
        });
      } else {
        setState(() {
          _isLoadingPdf = false;
          _errorMessage =
              '❌ Nu s-a putut încărca fișierul PDF (Status: ${res.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPdf = false;
        _errorMessage = '❌ Eroare la descărcarea documentului: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.docTitle.isNotEmpty
        ? widget.docTitle
        : 'Document Securizat';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isUnlocked && _pdfBytes != null
              ? _buildUnlockedPdfViewer()
              : _buildPinGatewayCard(),
        ),
      ),
    );
  }

  Widget _buildPinGatewayCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: 48,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'QualiAdept Secure Document',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Introduceți ultimele 4 cifre ale numărului de telefon pentru a debloca acest document.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(
                fontSize: 24,
                letterSpacing: 12,
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF475569)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF475569)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber, width: 2),
              ),
            ),
            onSubmitted: (_) => _verifyPin(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade200,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: _isLoadingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.lock_open),
              label: Text(
                _isLoadingPdf ? 'Se verifică...' : '🔓 Deblochează Documentul',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoadingPdf ? null : _verifyPin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedPdfViewer() {
    return SizedBox(
      height: 700,
      width: 900,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: PdfPreview(
          build: (format) => _pdfBytes!,
          allowPrinting: true,
          allowSharing: true,
          canChangeOrientation: false,
          canChangePageFormat: false,
          maxPageWidth: 800,
        ),
      ),
    );
  }
}
