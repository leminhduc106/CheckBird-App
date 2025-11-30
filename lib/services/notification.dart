import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Helper to check platform without using dart:io directly on web
bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'check_bird_reminders', // id
    'Task Reminders', // name
    description: 'Notifications for task and habit reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Android notification details
  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    'check_bird_reminders', // must match channel id
    'Task Reminders',
    channelDescription: 'Notifications for task and habit reminders',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'CheckBird Reminder',
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.reminder,
  );

  // iOS notification details
  static const DarwinNotificationDetails _iosNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _iosNotificationDetails,
  );

  factory NotificationService() {
    return _notificationService;
  }

  /// Check if notifications are enabled
  bool get isInitialized => _isInitialized;

  /// Request notification permissions for both Android and iOS
  Future<bool> requestPermission() async {
    bool granted = false;

    try {
      if (_isAndroid) {
        // Request notification permission (Android 13+)
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Request notification permission
          final notificationGranted =
              await androidPlugin.requestNotificationsPermission();
          granted = notificationGranted ?? false;

          // Request exact alarm permission (Android 12+)
          final exactAlarmGranted =
              await androidPlugin.requestExactAlarmsPermission();

          debugPrint(
              'NotificationService: Android notification permission granted: $granted, exact alarm: $exactAlarmGranted');
        }
      } else if (_isIOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          granted = await iosPlugin.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
              false;

          debugPrint(
              'NotificationService: iOS notification permission granted: $granted');
        }
      }
    } catch (e) {
      debugPrint('NotificationService: Error requesting permission: $e');
    }

    return granted;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Set local timezone
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Timezone set to $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Could not get timezone: $e');
      // Fallback to a default timezone
      tz.setLocalLocation(tz.getLocation('America/New_York'));
    }

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel (required for Android 8.0+)
    if (_isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        debugPrint(
            'NotificationService: Created notification channel: ${_channel.id}');
      }
    }

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');

    // Request permissions after initialization
    await requestPermission();

    // Debug: Check pending notifications
    await debugPendingNotifications();
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        'NotificationService: Notification tapped - id: ${response.id}, payload: ${response.payload}');
    // TODO: Navigate to the relevant task/todo based on payload
  }

  Future<void> createInstantNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      (title + body).hashCode,
      title,
      body,
      _notificationDetails,
    );
  }

  Future<void> createScheduleNotification(
      int id, String title, String body, DateTime dateTime,
      {String? payload}) async {
    // Validate that the scheduled time is in the future
    final now = DateTime.now();
    debugPrint(
        'NotificationService: createScheduleNotification called - id: $id, scheduledFor: $dateTime, currentTime: $now');

    if (dateTime.isBefore(now)) {
      debugPrint(
          'NotificationService: Cannot schedule notification in the past. Requested: $dateTime, Now: $now');
      return;
    }

    // Check exact alarm permission on Android
    if (_isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();
        debugPrint(
            'NotificationService: Can schedule exact alarms: $canScheduleExact');
        if (canScheduleExact != true) {
          debugPrint(
              'NotificationService: Exact alarm permission not granted! Requesting...');
          await androidPlugin.requestExactAlarmsPermission();
        }
      }
    }

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    debugPrint(
        'NotificationService: Scheduling notification - id: $id, title: $title, scheduledAt: $scheduledDate (TZ: ${tz.local.name})');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
          'NotificationService: Successfully scheduled notification id: $id');

      // Verify the notification was scheduled
      final pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final scheduled =
          pendingNotifications.any((notification) => notification.id == id);
      debugPrint(
          'NotificationService: Verified notification is in pending list: $scheduled');
    } catch (e, stackTrace) {
      debugPrint('NotificationService: Failed to schedule notification: $e');
      debugPrint('NotificationService: Stack trace: $stackTrace');
    }
  }

  Future<void> cancelScheduledNotifications(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('NotificationService: Cancelled notification id: $id');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  /// Debug: Print all pending notifications
  Future<void> debugPendingNotifications() async {
    final pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    debugPrint(
        'NotificationService: Pending notifications count: ${pendingNotifications.length}');

    for (final notification in pendingNotifications) {
      debugPrint(
          '  - id: ${notification.id}, title: ${notification.title}, body: ${notification.body}');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Check if a specific notification is scheduled
  Future<bool> isNotificationScheduled(int id) async {
    final pending = await getPendingNotifications();
    return pending.any((n) => n.id == id);
  }
}
