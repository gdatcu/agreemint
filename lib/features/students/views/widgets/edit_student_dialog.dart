import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/student_model.dart';
import '../../controllers/student_controller.dart';

/// Helper function to strip Romanian diacritics (ă, â, î, ș, ț etc.) from text.
String removeRomanianDiacritics(String text) {
  const Map<String, String> diacriticsMap = {
    'ă': 'a', 'Ă': 'A',
    'â': 'a', 'Â': 'A',
    'î': 'i', 'Î': 'I',
    'ș': 's', 'Ș': 'S',
    'ş': 's', 'Ş': 'S',
    'ț': 't', 'Ț': 'T',
    'ţ': 't', 'Ţ': 'T',
  };
  String result = text;
  diacriticsMap.forEach((key, value) {
    result = result.replaceAll(key, value);
  });
  return result;
}

class EditStudentDialog extends ConsumerStatefulWidget {
  final StudentModel student;
  final String programId;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.programId,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentModel student,
    required String programId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditStudentDialog(
        student: student,
        programId: programId,
      ),
    );
  }

  @override
  ConsumerState<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends ConsumerState<EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cuiController;
  late final TextEditingController _regComController;
  late final TextEditingController _billingAddressController;
  late String _clientType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _cuiController = TextEditingController(text: widget.student.cui ?? '');
    _regComController = TextEditingController(text: widget.student.regCom ?? '');
    _billingAddressController =
        TextEditingController(text: widget.student.billingAddress ?? '');
    _clientType = widget.student.clientType.isNotEmpty
        ? widget.student.clientType
        : 'PF';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cuiController.dispose();
    _regComController.dispose();
    _billingAddressController.dispose();
    super.dispose();
  }

  void _stripDiacritics() {
    final stripped = removeRomanianDiacritics(_nameController.text);
    _nameController.text = stripped;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: stripped.length),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(programEnrollmentsControllerProvider(widget.programId).notifier)
          .updateStudentDetails(
            studentId: widget.student.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            clientType: _clientType,
            cui: _cuiController.text.trim().isNotEmpty
                ? _cuiController.text.trim()
                : null,
            regCom: _regComController.text.trim().isNotEmpty
                ? _regComController.text.trim()
                : null,
            billingAddress: _billingAddressController.text.trim().isNotEmpty
                ? _billingAddressController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datele cursantului au fost actualizate cu succes!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la actualizarea cursantului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Editare Date Cursant'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field & Diacritics Helper
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nume Complet *',
                    hintText: 'ex: Bălan Lorena-Dumitrița sau Balan Lorena',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: Tooltip(
                      message: 'Elimină diacriticele din nume (ă, î, ș, ț, â ➔ a, i, s, t, a)',
                      child: TextButton.icon(
                        onPressed: _stripDiacritics,
                        icon: const Icon(Icons.spellcheck, size: 16),
                        label: const Text('Fără Diacritice', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Numele este obligatoriu' : null,
                ),
                const SizedBox(height: 12),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'ex: lorena.balan@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) =>
                      val == null || !val.contains('@') ? 'Introduceți un email valid' : null,
                ),
                const SizedBox(height: 12),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    hintText: 'ex: +40 745 152 264',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Client Type Selector
                Row(
                  children: [
                    const Text('Tip Client:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'PF', label: Text('PF (Persoană Fizică)')),
                        ButtonSegment(value: 'PFA', label: Text('PFA / PJ')),
                      ],
                      selected: {_clientType == 'PF' ? 'PF' : 'PFA'},
                      onSelectionChanged: (set) {
                        setState(() {
                          _clientType = set.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // CNP / CUI Field
                TextFormField(
                  controller: _cuiController,
                  decoration: InputDecoration(
                    labelText: _clientType == 'PF' ? 'CNP (Opțional)' : 'CUI / CIF Companie',
                    hintText: _clientType == 'PF' ? '13 cifre' : 'ex: RO12345678',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                if (_clientType != 'PF') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _regComController,
                    decoration: const InputDecoration(
                      labelText: 'Nr. Reg. Com.',
                      hintText: 'ex: J40/1234/2024 sau F40/123/2026',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Billing Address Field
                TextFormField(
                  controller: _billingAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresă Facturare / Domiciliu',
                    hintText: 'ex: Str. Florilor Nr. 12, București',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Salvează'),
        ),
      ],
    );
  }
}
