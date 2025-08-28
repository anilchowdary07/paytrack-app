import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:payment_reminder_app/models/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  Future<void> scheduleNotification(Payment payment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;

      if (!notificationsEnabled) {
        return;
      }

      final leadTimeDays = prefs.getInt('leadTimeDays') ?? 1;
      final timeString = prefs.getString('notificationTime') ?? '9:0';
      final parts = timeString.split(':');
      final notificationTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      final now = DateTime.now();
      final dueDate = payment.dueDate;

      DateTime scheduleTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - leadTimeDays,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (scheduleTime.isBefore(now)) {
        return; // Don't schedule for past dates
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'payment_reminder_channel',
            'Payment Reminders',
            channelDescription: 'Channel for payment reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        payment.id.hashCode,
        'Payment Reminder',
        'Your payment for ${payment.name} of ₹${payment.amount} is due in $leadTimeDays day${leadTimeDays > 1 ? 's' : ''}.',
        tz.TZDateTime.from(scheduleTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel for test notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // Test notification ID
        'Test Notification',
        'This is a test notification from PayTrack! Notifications are working correctly.',
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}
