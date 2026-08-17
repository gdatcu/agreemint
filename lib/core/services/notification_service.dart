import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/contracts/models/contract_model.dart';
import '../../features/payments/models/payment_model.dart';
import '../../features/prospects/models/prospect_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initializes local notifications for Android, iOS, and Web.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
      );
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if platform is unsupported (e.g. unit tests / web fallback)
    }
  }

  /// Prompts for notification permission on Android 13+ (API 33+) and iOS.
  static Future<bool> requestPermission() async {
    try {
      final androidImpl =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Evaluates pending payments list and dispatches an Android notification at most ONCE PER DAY.
  static Future<void> checkAndNotifyOverduePayments(
      List<PaymentModel> payments) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final actionRequiredPayments = payments.where((p) {
      if (p.status == 'Paid' || p.status == 'Refunded') return false;
      final due = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
      return due.isBefore(tomorrow) || due.isAtSameMomentAs(tomorrow);
    }).toList();

    if (actionRequiredPayments.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString('last_overdue_notified_date');
      if (lastNotified == todayStr) {
        // Notification already sent today – skip to prevent loop/spam
        return;
      }

      final studentCount = actionRequiredPayments
          .map((p) => p.enrollment?.student?.name ?? 'Cursant')
          .toSet()
          .length;

      final title =
          '🔔 ${actionRequiredPayments.length} Payment Reminder${actionRequiredPayments.length > 1 ? 's' : ''} Due!';
      final body = studentCount == 1
          ? '${actionRequiredPayments.first.enrollment?.student?.name ?? 'Student'} has an upcoming or past due payment.'
          : '$studentCount students have payments requiring attention.';

      await showOverdueNotification(id: 101, title: title, body: body);
      await prefs.setString('last_overdue_notified_date', todayStr);
    } catch (_) {}
  }

  /// Evaluates prospects list and dispatches an Android notification at most ONCE PER DAY.
  static Future<void> checkAndNotifyProspects(
      List<ProspectModel> prospects) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final dueProspects = prospects.where((p) {
      if (p.status == 'Converted' || p.status == 'Lost') return false;
      final due = DateTime(
          p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
      return due.isBefore(today) || due.isAtSameMomentAs(today);
    }).toList();

    if (dueProspects.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString('last_prospect_notified_date');
      if (lastNotified == todayStr) {
        // Notification already sent today – skip to prevent loop/spam
        return;
      }

      final title =
          '🔔 ${dueProspects.length} Prospect Follow-up${dueProspects.length > 1 ? 's' : ''} Due!';
      final body = dueProspects.length == 1
          ? 'Don\'t forget to follow up with ${dueProspects.first.name}.'
          : '${dueProspects.length} prospects are waiting for a follow-up today.';

      await showOverdueNotification(id: 202, title: title, body: body);
      await prefs.setString('last_prospect_notified_date', todayStr);
    } catch (_) {}
  }

  /// Evaluates contracts list and dispatches an Android notification for unsigned contracts issued >= 1 day ago.
  static Future<void> checkAndNotifyUnsignedContracts(
      List<ContractModel> contracts) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final unsignedContracts = contracts.where((c) {
      if (c.status == 'FullySigned' || c.status == 'Signed') return false;
      if (c.clientSignatureUrl != null && c.clientSignatureUrl!.isNotEmpty) return false;
      if (c.signedPdfUrl != null && c.signedPdfUrl!.isNotEmpty) return false;
      if (c.status == 'Cancelled' || c.status == 'Refunded') return false;
      final created = DateTime(c.createdDate.year, c.createdDate.month, c.createdDate.day);
      return created.isBefore(today);
    }).toList();

    if (unsignedContracts.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString('last_unsigned_contract_notified_date');
      if (lastNotified == todayStr) {
        return;
      }

      final studentCount = unsignedContracts
          .map((c) => c.studentName ?? 'Cursant')
          .toSet()
          .length;

      final title =
          '🔔 ${unsignedContracts.length} Contract${unsignedContracts.length > 1 ? 'e' : ''} Nesemnat${unsignedContracts.length > 1 ? 'e' : ''}!';
      final body = studentCount == 1
          ? '${unsignedContracts.first.studentName ?? 'Student'} nu a semnat încă contractul.'
          : '$studentCount cursanți au contracte generate ce așteaptă semnătura.';

      await showOverdueNotification(id: 303, title: title, body: body);
      await prefs.setString('last_unsigned_contract_notified_date', todayStr);
    } catch (_) {}
  }

  /// Evaluates prospects list and dispatches an Android push notification for pending follow-ups due today or overdue.
  static Future<void> checkAndNotifyProspectFollowUps(
      List<ProspectModel> prospects) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final dueProspects = prospects.where((p) {
      if (p.status == 'Converted') return false;
      final followUp = DateTime(
          p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
      return !followUp.isAfter(today);
    }).toList();

    if (dueProspects.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified =
          prefs.getString('last_prospect_followup_notified_date');
      if (lastNotified == todayStr) {
        return;
      }

      final count = dueProspects.length;
      final title =
          '🔔 $count Prospecț${count > 1 ? 'i' : 't'} Așteaptă Follow-up!';
      final body = count == 1
          ? '${dueProspects.first.name} necesită urmărire/follow-up astăzi.'
          : 'Aveți $count prospecți ce necesită urmărire/follow-up astăzi.';

      await showOverdueNotification(id: 304, title: title, body: body);
      await prefs.setString('last_prospect_followup_notified_date', todayStr);
    } catch (_) {}
  }

  /// Triggers a native heads-up notification banner with high priority, sound, and vibration.
  static Future<void> showOverdueNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'overdue_payments_channel',
      'Overdue Payment Alerts',
      channelDescription:
          'Notifications for past due student payment installments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }
}
