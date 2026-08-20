import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../controllers/business_settings_controller.dart';
import '../models/business_settings_model.dart';

class BusinessSettingsView extends ConsumerStatefulWidget {
  const BusinessSettingsView({super.key});

  @override
  ConsumerState<BusinessSettingsView> createState() =>
      _BusinessSettingsViewState();
}

class _BusinessSettingsViewState extends ConsumerState<BusinessSettingsView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _regComController;
  late TextEditingController _cuiCifController;
  late TextEditingController _euidController;
  late TextEditingController _ibanController;
  late TextEditingController _bankNameController;
  late TextEditingController _beneficiaryEntityController;
  late TextEditingController _serviceDescriptionController;
  late TextEditingController _paymentTermController;
  late TextEditingController _refundDeadlineController;

  late SignatureController _signatureController;
  Uint8List? _existingSignatureBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue.shade900,
      exportBackgroundColor: Colors.white,
    );

    final settings =
        ref.read(businessSettingsControllerProvider).asData?.value ??
            ref.read(businessSettingsControllerProvider).value ??
            const BusinessSettingsModel();

    _initControllers(settings);
  }

  void _initControllers(BusinessSettingsModel settings) {
    _companyNameController =
        TextEditingController(text: settings.companyName);
    _companyAddressController =
        TextEditingController(text: settings.companyAddress);
    _regComController = TextEditingController(text: settings.regCom);
    _cuiCifController = TextEditingController(text: settings.cuiCif);
    _euidController = TextEditingController(text: settings.euid);
    _ibanController = TextEditingController(text: settings.iban);
    _bankNameController = TextEditingController(text: settings.bankName);
    _beneficiaryEntityController =
        TextEditingController(text: settings.beneficiaryEntity);
    _serviceDescriptionController =
        TextEditingController(text: settings.serviceDescription);
    _paymentTermController =
        TextEditingController(text: settings.paymentTerm);
    _refundDeadlineController =
        TextEditingController(text: settings.refundDeadline);

    _existingSignatureBytes = settings.mentorSignatureBytes;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _regComController.dispose();
    _cuiCifController.dispose();
    _euidController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _beneficiaryEntityController.dispose();
    _serviceDescriptionController.dispose();
    _paymentTermController.dispose();
    _refundDeadlineController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? mentorSigBase64;
      if (_signatureController.isNotEmpty) {
        final sigBytes = await _signatureController.toPngBytes();
        if (sigBytes != null) {
          mentorSigBase64 = base64Encode(sigBytes);
        }
      } else if (_existingSignatureBytes != null) {
        mentorSigBase64 = base64Encode(_existingSignatureBytes!);
      } else {
        final currentSettings = ref.read(businessSettingsControllerProvider).asData?.value ??
            ref.read(businessSettingsControllerProvider).value;
        mentorSigBase64 = currentSettings?.mentorSignatureBase64;
      }

      final updatedSettings = BusinessSettingsModel(
        companyName: _companyNameController.text.trim(),
        companyAddress: _companyAddressController.text.trim(),
        regCom: _regComController.text.trim(),
        cuiCif: _cuiCifController.text.trim(),
        euid: _euidController.text.trim(),
        iban: _ibanController.text.trim(),
        bankName: _bankNameController.text.trim(),
        beneficiaryEntity: _beneficiaryEntityController.text.trim(),
        serviceDescription: _serviceDescriptionController.text.trim(),
        paymentTerm: _paymentTermController.text.trim(),
        refundDeadline: _refundDeadlineController.text.trim(),
        mentorSignatureBase64: mentorSigBase64,
      );

      await ref
          .read(businessSettingsControllerProvider.notifier)
          .updateSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business & Contract Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(businessSettingsControllerProvider);

    ref.listen<AsyncValue<BusinessSettingsModel>>(
      businessSettingsControllerProvider,
      (previous, next) {
        next.whenData((settings) {
          if (_existingSignatureBytes == null && settings.mentorSignatureBytes != null) {
            setState(() {
              _existingSignatureBytes = settings.mentorSignatureBytes;
            });
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business & Contract Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: _showResetConfirmationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Save Settings',
            onPressed: _isSaving ? null : _saveSettings,
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (_existingSignatureBytes == null && settings.mentorSignatureBytes != null) {
            _existingSignatureBytes = settings.mentorSignatureBytes;
          }
          if (_companyNameController.text.isEmpty) {
            _companyNameController.text = settings.companyName;
            _companyAddressController.text = settings.companyAddress;
            _regComController.text = settings.regCom;
            _cuiCifController.text = settings.cuiCif;
            _euidController.text = settings.euid;
            _ibanController.text = settings.iban;
            _bankNameController.text = settings.bankName;
            _beneficiaryEntityController.text = settings.beneficiaryEntity;
            _serviceDescriptionController.text = settings.serviceDescription;
            _paymentTermController.text = settings.paymentTerm;
            _refundDeadlineController.text = settings.refundDeadline;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Company Profile
                  _buildSectionHeader(
                    icon: Icons.business_rounded,
                    title: 'Company & Banking Information (Prestator)',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _companyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Company / PFA Name',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required field'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _companyAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Sediu / Billing Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            maxLines: 2,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required field'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cuiCifController,
                                  decoration: const InputDecoration(
                                    labelText: 'CUI / CIF',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _regComController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reg. Com. No.',
                                    prefixIcon:
                                        Icon(Icons.confirmation_number_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _ibanController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bank IBAN',
                                    prefixIcon:
                                        Icon(Icons.account_balance_wallet_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _bankNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bank Name',
                                    prefixIcon:
                                        Icon(Icons.account_balance_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Default Contract Terms
                  _buildSectionHeader(
                    icon: Icons.description_rounded,
                    title: 'Default Contract & Service Terms',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _beneficiaryEntityController,
                            decoration: const InputDecoration(
                              labelText: 'Beneficiary Entity / Community Name',
                              prefixIcon: Icon(Icons.groups_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _serviceDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Service Description (RO)',
                              prefixIcon: Icon(Icons.notes_outlined),
                              hintText:
                                  'e.g., sesiuni live online, code review, consultanță',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _paymentTermController,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Term (Days)',
                                    prefixIcon: Icon(Icons.event_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _refundDeadlineController,
                                  decoration: const InputDecoration(
                                    labelText: 'Refund Deadline (Days)',
                                    prefixIcon:
                                        Icon(Icons.assignment_return_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Default Mentor Signature
                  _buildSectionHeader(
                    icon: Icons.draw_rounded,
                    title: 'Default Mentor Signature',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Draw your default signature below to automatically embed into issued contracts and PDF receipts:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            height: 160,
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (_existingSignatureBytes != null &&
                                    _signatureController.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Image.memory(
                                        _existingSignatureBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                Signature(
                                  controller: _signatureController,
                                  backgroundColor: Colors.transparent,
                                  height: 160,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                label: const Text('Clear Signature'),
                                onPressed: () {
                                  _signatureController.clear();
                                  setState(() {
                                    _existingSignatureBytes = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save Business Settings',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load settings: $err'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      {required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset Settings to Defaults?'),
          content: const Text(
              'This will revert all business details, contract terms, and signature back to initial PFA defaults.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(businessSettingsControllerProvider.notifier)
                    .resetToDefaults();
                final defaults = const BusinessSettingsModel();
                setState(() {
                  _initControllers(defaults);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Settings reset to default PFA preset.')),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
