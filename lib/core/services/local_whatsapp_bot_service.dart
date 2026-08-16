import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocalWhatsAppBotService {
  static const String _keyServerUrl = 'local_bot_server_url';
  static const String _defaultUrl =
      'https://qualiadept-whatsapp-bot.onrender.com';

  /// Saves the bot server URL.
  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url.trim());
  }

  /// Gets the stored bot server URL.
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? _defaultUrl;
  }

  /// Checks bot server status.
  static Future<Map<String, dynamic>> checkStatus() async {
    final serverUrl = await getServerUrl();
    try {
      final res = await http
          .get(Uri.parse('$serverUrl/status'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'status': 'UNREACHABLE', 'authenticated': false};
  }

  /// Dispatches an automated WhatsApp payment reminder via the local/cloud bot.
  static Future<bool> sendReminder({
    required BuildContext context,
    required String recipientPhone,
    required String studentName,
    required String programName,
    required String amountStr,
    required String currency,
    required String dueDateStr,
  }) async {
    final serverUrl = await getServerUrl();

    if (recipientPhone.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number recorded for this student.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final payload = {
      'phone': recipientPhone,
      'studentName': studentName,
      'programName': programName,
      'amount': amountStr,
      'currency': currency,
      'dueDate': dueDateStr,
    };

    try {
      final res = await http.post(
        Uri.parse('$serverUrl/send-reminder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🤖 QualiAdept Bot sent message to $studentName!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        final errJson = jsonDecode(res.body);
        final errMsg = errJson['error'] ?? res.body;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bot Server Error: $errMsg'),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        _showBotConnectionErrorDialog(context, serverUrl);
      }
      return false;
    }
  }

  /// Dialog shown if local bot server is not reachable.
  static void _showBotConnectionErrorDialog(
      BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue),
              SizedBox(width: 8),
              Text('QualiAdept Bot Server Connection'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Could not connect to the WhatsApp Bot Server. Make sure the Node.js server is running or configure your server URL below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Bot Server URL',
                  hintText: 'http://localhost:3000 or Render URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To start local bot server:\n1. Run "npm start" inside server/ directory\n2. Open http://localhost:3000/qr to scan QR code once.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveServerUrl(controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bot Server URL updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save Server URL'),
            ),
          ],
        );
      },
    );
  }

  /// Triggers configuration settings modal.
  static void openSettings(BuildContext context) async {
    final currentUrl = await getServerUrl();
    if (context.mounted) {
      _showBotConnectionErrorDialog(context, currentUrl);
    }
  }
}
