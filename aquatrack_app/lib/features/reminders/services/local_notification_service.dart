import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_slot.dart';
import '../logic/tone_messages.dart';

/// Schedules the Hydration Schedule as on-device local notifications.
///
/// Timing is inexact by design (see ADR 0001): the OS may drift a few minutes,
/// which avoids the Android 12+ exact-alarm permission and Doze edge cases.
class LocalNotificationService {
  static const _channelId = 'hydration_reminders';
  static const _channelName = 'Lịch nhắc uống nước';
  static const _channelDesc = 'Nhắc bạn uống nước theo lịch trong ngày';

  static final LocalNotificationService instance = LocalNotificationService._();
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (e) {
      debugPrint('⏰ LocalNotification: tz fallback (UTC): $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Prompt for notification permission. Returns whether it is granted.
  Future<bool> requestPermission() async {
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// Whether notifications are currently allowed, without prompting.
  Future<bool> hasPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final opts = await ios?.checkPermissions();
      return opts?.isEnabled ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Cancel every scheduled reminder and reschedule the enabled [slots].
  Future<void> syncSchedule(List<ReminderSlot> slots) async {
    await init();
    await _plugin.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        // Signature app sound. NOTE: on Android 8+ the sound is frozen to the
        // channel at creation time — changing it later needs a NEW channel id
        // (see ADR 0001). Pre-release: just uninstall + reinstall to refresh.
        // File lives at android/app/src/main/res/raw/aquatrack_alert.wav
        // (referenced WITHOUT extension).
        sound: RawResourceAndroidNotificationSound('aquatrack_alert'),
      ),
      // iOS: file must be added to the Runner target's "Copy Bundle Resources"
      // (needs a Mac). Referenced WITH extension. Falls back to default sound
      // silently if the file isn't bundled.
      iOS: DarwinNotificationDetails(sound: 'aquatrack_alert.wav'),
    );

    var notificationId = 0;
    for (final slot in slots) {
      if (!slot.enabled) continue;
      await _plugin.zonedSchedule(
        notificationId++,
        reminderNotificationTitle,
        reminderBodyFor(slot.tone, slot.minutesOfDay),
        _nextInstanceOfTime(slot.hour, slot.minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
