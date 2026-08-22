import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../../../core/services/discord_notification_service.dart';
import '../../../core/services/email_service.dart';
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
  late TextEditingController _discordWebhookController;
  late TextEditingController _mentorNotificationEmailController;
  late TextEditingController _resendApiKeyController;

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
    _discordWebhookController =
        TextEditingController(text: settings.discordWebhookUrl ?? '');
    _mentorNotificationEmailController =
        TextEditingController(text: settings.mentorNotificationEmail ?? '');
    _resendApiKeyController =
        TextEditingController(text: settings.resendApiKey ?? '');

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
    _discordWebhookController.dispose();
    _mentorNotificationEmailController.dispose();
    _resendApiKeyController.dispose();
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
        discordWebhookUrl: _discordWebhookController.text.trim(),
        mentorNotificationEmail: _mentorNotificationEmailController.text.trim(),
        resendApiKey: _resendApiKeyController.text.trim(),
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
                  const SizedBox(height: 24),
                  _buildSoloIntegrationCard(),
                  const SizedBox(height: 24),
                  _buildDiscordIntegrationCard(),
                  const SizedBox(height: 24),
                  _buildEmailIntegrationCard(),
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

  Widget _buildSoloIntegrationCard() {
    const clientBookmarkletCode = r'''javascript:(async () => {
  try {
    const text = await navigator.clipboard.readText();
    const data = JSON.parse(text);
    
    const setVal = (el, val) => {
      if (!el || !val) return false;
      el.value = val;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.dispatchEvent(new Event('blur', { bubbles: true }));
      try {
        if (window.angular) {
          const ngEl = window.angular.element(el);
          ngEl.triggerHandler('input');
          ngEl.triggerHandler('change');
          const scope = ngEl.scope();
          if (scope) scope.$apply();
        }
      } catch(e) {}
      return true;
    };

    const findAndFill = (selector, keywords, val) => {
      if (!val) return false;
      let el = document.querySelector(selector);
      if (!el) {
        const inputs = Array.from(document.querySelectorAll('input, textarea'));
        el = inputs.find(i => {
          const t = (i.name || i.id || i.placeholder || '').toLowerCase();
          return keywords.some(k => t.includes(k));
        });
      }
      return setVal(el, val);
    };

    findAndFill('input[name="customer-name"], #customerName20', ['customer-name', 'nume'], data.clientName);
    findAndFill('input[name="customer-code1"]', ['customer-code1', 'cnp', 'code1'], data.clientCnp);
    findAndFill('input[name="customer-address"]', ['customer-address', 'adresa'], data.clientAddress);
    findAndFill('input[name="customer-email"]', ['customer-email', 'email'], data.clientEmail);
    findAndFill('input[name="customer-phone"]', ['customer-phone', 'telefon', 'phone'], data.clientPhone);

    alert("Formularul 'Adaugă client nou' a fost completat!\n\nNume: " + (data.clientName||'-') + "\nCNP: " + (data.clientCnp||'-') + "\nAdresă: " + (data.clientAddress||'-') + "\nEmail: " + (data.clientEmail||'-') + "\nTelefon: " + (data.clientPhone||'-'));
  } catch (e) {
    alert("Asigură-te că ai copiat datele din Agreemint și că ai permis accesul la clipboard.");
  }
})();''';

    const invoiceBookmarkletCode = r'''javascript:(async () => {
  try {
    const text = await navigator.clipboard.readText();
    const data = JSON.parse(text);
    
    const setVal = (el, val) => {
      if (!el || !val) return false;
      el.value = val;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.dispatchEvent(new Event('blur', { bubbles: true }));
      try {
        if (window.angular) {
          const ngEl = window.angular.element(el);
          ngEl.triggerHandler('input');
          ngEl.triggerHandler('change');
          const scope = ngEl.scope();
          if (scope) scope.$apply();
        }
      } catch(e) {}
      return true;
    };

    const findAndFill = (selector, keywords, val) => {
      if (!val) return false;
      let el = document.querySelector(selector);
      if (!el) {
        const inputs = Array.from(document.querySelectorAll('input, textarea'));
        el = inputs.find(i => {
          const t = (i.name || i.id || i.placeholder || '').toLowerCase();
          return keywords.some(k => t.includes(k));
        });
      }
      return setVal(el, val);
    };

    findAndFill('input[name="invoiceCustomer"], #invoiceCustomer', ['customer', 'client'], data.clientName);
    findAndFill('textarea[name="article-name0"]', ['article', 'articol'], data.productName);
    findAndFill('input[name="line-pu0"]', ['line-pu', 'pu', 'unitar'], data.amount ? data.amount.toString() : '');
    findAndFill('input[name="start-date"]', ['start-date', 'emitere'], data.issueDate);
    findAndFill('input[name="end-date"]', ['end-date', 'scadenta'], data.dueDate);

    alert("Formularul de Factură Draft a fost completat!\n\nClient: " + (data.clientName||'-') + "\nProdus: " + (data.productName||'-') + "\nPreț: " + (data.amount||'-') + " " + (data.currency||'RON') + "\nScadentă: " + (data.dueDate||'-'));
  } catch (e) {
    alert("Asigură-te că ai copiat datele din Agreemint și că ai permis accesul la clipboard.");
  }
})();''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.integration_instructions_rounded,
          title: 'SOLO Invoicing Integration Guide (For Mentors)',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.rocket_launch_outlined, color: Colors.blue.shade700, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SaaS Feature: 1-Click Invoice & Client Autofill',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mentors can create two bookmarklets on their browser bookmarks bar to autofill client registration and draft invoices in SOLO in 1 click:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Setup Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text('1. Press Ctrl + Shift + B to display your browser Bookmarks Bar.'),
                const SizedBox(height: 4),
                const Text('2. Right-click on your bookmarks bar and choose "Add page..." (Adaugă pagină).'),
                const SizedBox(height: 4),
                const Text('3. Add Bookmarklet 1: Name = "Autofill Client Nou", URL = paste Bookmarklet 1 Code below.'),
                const SizedBox(height: 4),
                const Text('4. Add Bookmarklet 2: Name = "Autofill Factură SOLO", URL = paste Bookmarklet 2 Code below.'),
                const SizedBox(height: 4),
                const Text('5. Click "Copiază date SOLO" on any unpaid installment in Agreemint.'),
                const SizedBox(height: 4),
                const Text('6. In SOLO: click "Autofill Client Nou" when adding a new client popup, and "Autofill Factură SOLO" on the invoice editor page!'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: clientBookmarkletCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bookmarklet 1 (Client Nou SOLO) copied to clipboard!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Copy Bookmarklet 1: Client Nou'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: invoiceBookmarkletCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bookmarklet 2 (Factură Draft SOLO) copied to clipboard!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Copy Bookmarklet 2: Factură Draft'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscordIntegrationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.notifications_active_rounded,
          title: 'Realtime Contract Notifications (Discord Webhook)',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.indigo.shade700, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Discord Real-Time Contract Signed Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Receive instant Discord push notifications on your phone/laptop whenever a student signs their contract, featuring direct links to the signed PDF contract!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discordWebhookController,
                  decoration: InputDecoration(
                    labelText: 'Discord Webhook URL',
                    hintText: 'https://discord.com/api/webhooks/...',
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.link_rounded, color: Colors.indigo.shade600),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = _discordWebhookController.text.trim();
                        if (url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Te rugăm să introduci un Webhook URL valid mai întâi.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final success =
                            await DiscordNotificationService.sendTestMessage(url);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '🎉 Mesaj de test trimis cu succes pe Discord!'
                                  : '❌ Trimiterea a eșuat. Verifică URL-ul Webhook.'),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Trimite Mesaj de Test Discord'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailIntegrationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.mark_email_read_rounded,
          title: 'Realtime Contract Notifications (Email Alert)',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.email_outlined,
                          color: Colors.green.shade700, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Email Alerts for Signed Contracts',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Receive instant email alerts in your inbox whenever a student signs a contract, featuring student details and a direct link to the signed PDF contract.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mentorNotificationEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Adresă Email Notificări Mentor',
                    hintText: 'danielioanmarcu@yahoo.com sau me@georgedatcu.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resendApiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Cheie API Resend (Opțional pentru trimitere directă)',
                    hintText: 're_123456789...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final email = _mentorNotificationEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Te rugăm să introduci o adresă email validă mai întâi.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final result = await EmailService.sendTestEmailAlert(
                          mentorEmail: email,
                          resendApiKey: _resendApiKeyController.text.trim(),
                        );
                        if (context.mounted) {
                          final isSuccess = result['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Notificare finalizată.'),
                              backgroundColor: isSuccess ? Colors.green : Colors.orange.shade800,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Trimite Email de Test'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
