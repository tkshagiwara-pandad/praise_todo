// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'todo_praise_channel';
  static const String _channelName = 'Todo Praise';
  static const String _channelDesc = 'Todo完了や日次まとめの褒め通知';

  Future<void> init() async {
    if (_initialized) return;

    // iOS
    const iosInit = DarwinInitializationSettings();

    // Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: DarwinInitializationSettings(),
    );

    // ✅ v20: initialize は named 引数
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 通知タップ時のハンドリングが必要になったらここ
      },
    );

    // ✅ permission (iOS)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // ✅ permission (Android 13+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    // ✅ timezone（zonedSchedule用）
    tz_data.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    _initialized = true;
  }

  NotificationDetails _details() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// いますぐ通知
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    // ✅ v20: show は named 引数
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  /// テスト用：1分後通知（OS予約）
  Future<void> scheduleInOneMinute({
    required String title,
    required String body,
    int id = 1001,
  }) async {
    await init();
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

    // ✅ v20: zonedSchedule は named 引数 / uiLocalNotificationDateInterpretation は削除済み
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test_1min',
    );
  }

  /// 毎日22:30 予約（ID固定運用）
  Future<void> scheduleDaily2230({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      30,
    );

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: next,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 毎日同時刻
      payload: 'daily_2230',
    );
  }

  Future<void> cancel(int id) async {
    await init();
    // ✅ v20: cancel も named 引数
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }
}
