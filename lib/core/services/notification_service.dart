import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Evaluates pending payments list and dispatches an Android notification if overdue payments exist.
  static Future<void> checkAndNotifyOverduePayments(
      List<PaymentModel> payments) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overduePayments = payments.where((p) {
      final due = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
      return due.isBefore(today) &&
          p.status != 'Paid' &&
          p.status != 'Refunded';
    }).toList();

    if (overduePayments.isEmpty) return;

    final studentCount = overduePayments
        .map((p) => p.enrollment?.student?.name ?? 'Cursant')
        .toSet()
        .length;

    final title =
        '⚠️ ${overduePayments.length} Overdue Payment${overduePayments.length > 1 ? 's' : ''}!';
    final body = studentCount == 1
        ? '${overduePayments.first.enrollment?.student?.name ?? 'Student'} has an overdue payment.'
        : '$studentCount students have payments past their due date.';

    await showOverdueNotification(id: 101, title: title, body: body);
  }

  /// Evaluates prospects list and dispatches an Android notification if follow-ups are due today or overdue.
  static Future<void> checkAndNotifyProspects(
      List<ProspectModel> prospects) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueProspects = prospects.where((p) {
      if (p.status == 'Converted' || p.status == 'Lost') return false;
      final due = DateTime(
          p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
      return due.isBefore(today) || due.isAtSameMomentAs(today);
    }).toList();

    if (dueProspects.isEmpty) return;

    final title =
        '🔔 ${dueProspects.length} Prospect Follow-up${dueProspects.length > 1 ? 's' : ''} Due!';
    final body = dueProspects.length == 1
        ? 'Don\'t forget to follow up with ${dueProspects.first.name}.'
        : '${dueProspects.length} prospects are waiting for a follow-up today.';

    await showOverdueNotification(id: 202, title: title, body: body);
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
