import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PaymentReminder model for notifications
class PaymentReminder {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String category;
  final TimeOfDay reminderTime;
  final List<int> reminderDaysBefore;
  final String priority;
  final String notes;

  PaymentReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.reminderTime,
    required this.reminderDaysBefore,
    required this.priority,
    required this.notes,
  });
}

class NotificationService {
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  Future<void> init() async {
    // Initialize notification system
    debugPrint('Notification service initialized');
  }

  Future<void> scheduleNotification(PaymentReminder reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;

      if (!notificationsEnabled) {
        return;
      }

      final now = DateTime.now();
      List<Map<String, dynamic>> scheduledNotifications = [];

      // Schedule notifications for each reminder day
      for (int daysBefore in reminder.reminderDaysBefore) {
        DateTime notificationDate = DateTime(
          reminder.dueDate.year,
          reminder.dueDate.month,
          reminder.dueDate.day - daysBefore,
          reminder.reminderTime.hour,
          reminder.reminderTime.minute,
        );

        // Only schedule if the notification time is in the future
        if (notificationDate.isAfter(now)) {
          scheduledNotifications.add({
            'id': '${reminder.id}_$daysBefore',
            'reminderId': reminder.id,
            'title': 'Payment Reminder',
            'body':
                'Your payment for ${reminder.name} of ₹${reminder.amount} is due in $daysBefore day${daysBefore > 1 ? 's' : ''}.',
            'scheduledTime': notificationDate.millisecondsSinceEpoch,
            'daysBefore': daysBefore,
            'priority': reminder.priority,
          });

          debugPrint(
              'Scheduled notification for ${reminder.name} at $notificationDate ($daysBefore days before)');
        } else {
          debugPrint(
              'Skipped past notification for ${reminder.name} at $notificationDate');
        }
      }

      // Save scheduled notifications to preferences
      if (scheduledNotifications.isNotEmpty) {
        await _saveScheduledNotifications(scheduledNotifications);
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _saveScheduledNotifications(
      List<Map<String, dynamic>> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? existingNotifications =
          prefs.getStringList(_scheduledNotificationsKey);
      List<String> allNotifications = [];

      // Load existing notifications
      if (existingNotifications != null) {
        allNotifications.addAll(existingNotifications);
      }

      // Add new notifications
      for (Map<String, dynamic> notification in notifications) {
        String notificationString =
            '${notification['id']}|${notification['reminderId']}|${notification['title']}|${notification['body']}|${notification['scheduledTime']}|${notification['daysBefore']}|${notification['priority']}';
        allNotifications.add(notificationString);
      }

      // Save back to preferences
      await prefs.setStringList(_scheduledNotificationsKey, allNotifications);
    } catch (e) {
      debugPrint('Error saving scheduled notifications: $e');
    }
  }

  Future<void> cancelNotification(String reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? existingNotifications =
          prefs.getStringList(_scheduledNotificationsKey);

      if (existingNotifications != null) {
        // Remove notifications for this reminder
        List<String> filteredNotifications = existingNotifications
            .where((n) => !n.split('|')[1].contains(reminderId))
            .toList();

        await prefs.setStringList(
            _scheduledNotificationsKey, filteredNotifications);
        debugPrint('Cancelled notifications for reminder: $reminderId');
      }
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? notificationStrings =
          prefs.getStringList(_scheduledNotificationsKey);

      if (notificationStrings == null) return [];

      final now = DateTime.now();
      List<Map<String, dynamic>> pendingNotifications = [];

      for (String notificationString in notificationStrings) {
        List<String> parts = notificationString.split('|');
        if (parts.length >= 7) {
          DateTime scheduledTime =
              DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4]));

          if (scheduledTime.isAfter(now)) {
            pendingNotifications.add({
              'id': parts[0],
              'reminderId': parts[1],
              'title': parts[2],
              'body': parts[3],
              'scheduledTime': scheduledTime,
              'daysBefore': int.parse(parts[5]),
              'priority': parts[6],
            });
          }
        }
      }

      return pendingNotifications;
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  Future<void> showTestNotification() async {
    debugPrint('Test notification: PayTrack notifications are working!');
    // Show a simple debug message for now
    // In a real app, this would trigger an actual notification
  }

  // Check for due notifications and show them
  Future<void> checkAndShowDueNotifications() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final now = DateTime.now();

      for (Map<String, dynamic> notification in pendingNotifications) {
        DateTime scheduledTime = notification['scheduledTime'];

        // Check if notification is due (within 1 minute of scheduled time)
        if (now.isAfter(scheduledTime) &&
            now.difference(scheduledTime).inMinutes <= 1) {
          debugPrint(
              '📱 NOTIFICATION: ${notification['title']} - ${notification['body']}');

          // In a real app, this would show an actual notification
          // For now, we'll just log it
        }
      }
    } catch (e) {
      debugPrint('Error checking due notifications: $e');
    }
  }
}
