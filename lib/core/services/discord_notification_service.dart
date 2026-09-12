import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DiscordNotificationService {
  /// Sends a rich Discord embed notification when a contract is signed by a student.
  static Future<bool> notifyContractSigned({
    required String webhookUrl,
    required String studentName,
    required String studentCnp,
    required String programName,
    required int contractNumber,
    required String signedPdfUrl,
    String? signedDateStr,
  }) async {
    final cleanUrl = webhookUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return false;

    final dateText = signedDateStr ??
        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final payload = {
      'username': 'Agreemint Bot',
      'avatar_url': 'https://agreemint.qualiadept.eu/icons/Icon-192.png',
      'embeds': [
        {
          'title': '✍️ Contract Semnat de Cursant!',
          'description':
              'Studentul **$studentName** a semnat contractul **nr. $contractNumber**!',
          'color': 3066993, // Green theme #2ECC71
          'fields': [
            {
              'name': '👤 Client',
              'value': studentName,
              'inline': true,
            },
            {
              'name': '🆔 CNP / CUI',
              'value': studentCnp.isNotEmpty ? studentCnp : '-',
              'inline': true,
            },
            {
              'name': '🎓 Program',
              'value': programName,
              'inline': true,
            },
            {
              'name': '📅 Data & Ora Semnării',
              'value': dateText,
              'inline': true,
            },
            {
              'name': '📄 Contract PDF Semnat',
              'value': signedPdfUrl.isNotEmpty
                  ? '[👁️ Deschide / Descarcă PDF Semnat]($signedPdfUrl)'
                  : 'PDF indisponibil',
              'inline': false,
            },
          ],
          'footer': {
            'text': 'Agreemint Realtime Notification System • QualiAdept',
          },
          'timestamp': DateTime.now().toIso8601String(),
        }
      ],
    };

    try {
      final res = await http.post(
        Uri.parse(cleanUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Failed to send Discord Webhook notification: $e');
      return false;
    }
  }

  /// Sends a rich Discord embed notification for upcoming or today's celebrations (Birthdays & Name Days).
  static Future<bool> notifyCelebrations({
    required String webhookUrl,
    required List<dynamic> celebrations, // List<CelebrationEvent>
  }) async {
    final cleanUrl = webhookUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return false;
    if (celebrations.isEmpty) return false;

    final fields = <Map<String, dynamic>>[];
    for (final event in celebrations) {
      final studentName = event.student.name;
      final typeIcon = event.type.toString().contains('birthday') ? '🎂' : '🌸';
      final timing = event.daysUntil == 0
          ? '🎉 **ASTĂZI**'
          : (event.daysUntil == 1 ? '⏰ Mâine' : '📅 în ${event.daysUntil} zile (${event.date.day}.${event.date.month})');

      fields.add({
        'name': '$typeIcon $studentName',
        'value': '$timing • **${event.title}**${event.student.phone != null && event.student.phone!.isNotEmpty ? '\n📞 ${event.student.phone}' : ''}',
        'inline': false,
      });
    }

    final payload = {
      'username': 'Agreemint Celebrations',
      'avatar_url': 'https://agreemint.qualiadept.eu/icons/Icon-192.png',
      'embeds': [
        {
          'title': '🎉 Sărbătoriții Cursanți (Zile de Naștere & Onomastică)',
          'description':
              'Iată cursanții care își sărbătoresc ziua de naștere sau onomastica în perioada următoare:',
          'color': 15844367, // Gold/Champagne #F1C40F
          'fields': fields,
          'footer': {
            'text': 'Agreemint Community & Celebrations Hub • QualiAdept',
          },
          'timestamp': DateTime.now().toIso8601String(),
        }
      ],
    };

    try {
      final res = await http.post(
        Uri.parse(cleanUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Failed to send Discord celebrations notification: $e');
      return false;
    }
  }

  /// Sends a test message to verify Discord Webhook configuration.
  static Future<bool> sendTestMessage(String webhookUrl) async {
    final cleanUrl = webhookUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return false;

    final payload = {
      'username': 'Agreemint Bot',
      'avatar_url': 'https://agreemint.qualiadept.eu/icons/Icon-192.png',
      'content': '✅ **Test Webhook Discord Reușit!** Notificările de contracte semnate sunt configurate activ în Agreemint.',
    };
    try {
      final res = await http.post(
        Uri.parse(cleanUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Failed to send Discord test message: $e');
      return false;
    }
  }
}

