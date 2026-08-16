import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'whatsapp_reminder_service.dart';

class MetaWhatsAppService {
  static const String _keyPhoneNumberId = 'meta_phone_number_id';
  static const String _keyAccessToken = 'meta_access_token';
  static const String _keyTemplateName = 'meta_template_name';

  /// Saves Meta credentials to SharedPreferences.
  static Future<void> saveConfig({
    required String phoneNumberId,
    required String accessToken,
    String templateName = 'hello_world',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoneNumberId, phoneNumberId.trim());
    await prefs.setString(_keyAccessToken, accessToken.trim());
    await prefs.setString(_keyTemplateName, templateName.trim());
  }

  /// Gets stored Meta credentials.
  static Future<Map<String, String>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phoneNumberId': prefs.getString(_keyPhoneNumberId) ?? '1264011373461547',
      'accessToken': prefs.getString(_keyAccessToken) ?? '',
      'templateName': prefs.getString(_keyTemplateName) ?? 'hello_world',
    };
  }

  /// Sends an automated WhatsApp template message via Meta Cloud API.
  static Future<bool> sendTemplateMessage({
    required BuildContext context,
    required String recipientPhone,
    required String studentName,
    required String programName,
    required String amountStr,
    required String dueDateStr,
  }) async {
    final config = await getConfig();
    final phoneId = config['phoneNumberId']!;
    final token = config['accessToken']!;
    final templateName = config['templateName']!;

    if (phoneId.isEmpty || token.isEmpty) {
      if (context.mounted) {
        _showConfigDialog(context);
      }
      return false;
    }

    final cleanedPhone = WhatsAppReminderService.cleanPhoneNumber(recipientPhone);
    final url = Uri.parse('https://graph.facebook.com/v25.0/$phoneId/messages');

    Map<String, dynamic> bodyPayload;

    if (templateName == 'hello_world') {
      // Default Meta test template
      bodyPayload = {
        'messaging_product': 'whatsapp',
        'to': cleanedPhone,
        'type': 'template',
        'template': {
          'name': 'hello_world',
          'language': {'code': 'en_US'},
        },
      };
    } else {
      // Custom payment reminder template
      bodyPayload = {
        'messaging_product': 'whatsapp',
        'to': cleanedPhone,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {'code': 'ro'},
          'components': [
            {
              'type': 'body',
              'parameters': [
                {'type': 'text', 'text': studentName},
                {'type': 'text', 'text': amountStr},
                {'type': 'text', 'text': programName},
                {'type': 'text', 'text': dueDateStr},
              ],
            }
          ],
        },
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyPayload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🤖 Meta WhatsApp Bot sent message to $studentName!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? response.body;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meta Bot Error: $errMsg'),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error sending Meta Bot message: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return false;
    }
  }

  /// Opens dialog to configure Meta credentials inside Agreemint.
  static void _showConfigDialog(BuildContext context) async {
    final config = await getConfig();
    final phoneIdController = TextEditingController(text: config['phoneNumberId']);
    final tokenController = TextEditingController(text: config['accessToken']);
    final templateController = TextEditingController(text: config['templateName']);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue),
              SizedBox(width: 8),
              Text('Meta WhatsApp Bot Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure Meta WhatsApp Cloud API credentials to enable automated bot messaging:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneIdController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number ID',
                    hintText: '1264011373461547',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Access Token',
                    hintText: 'Paste Meta Access Token...',
                    prefixIcon: Icon(Icons.key),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: templateController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'hello_world or payment_overdue_reminder',
                    prefixIcon: Icon(Icons.subtitles),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await saveConfig(
                  phoneNumberId: phoneIdController.text,
                  accessToken: tokenController.text,
                  templateName: templateController.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meta Bot Settings saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save Credentials'),
            ),
          ],
        );
      },
    );
  }

  /// Exposes dialog trigger for settings menu.
  static void openSettings(BuildContext context) {
    _showConfigDialog(context);
  }
}
