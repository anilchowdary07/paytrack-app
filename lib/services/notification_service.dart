import 'package:flutter/material.dart';

class NotificationService {
  static NotificationService? _instance;

  NotificationService._internal();

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  Future<void> init() async {
    // Initialize notification service
    // In a real app, you would initialize flutter_local_notifications here
    print('NotificationService initialized');
  }

  Future<void> scheduleNotification(PaymentReminder reminder) async {
    // Schedule notification for the payment reminder
    // In a real app, you would use flutter_local_notifications to schedule
    print('Scheduling notification for: ${reminder.name}');

    // Calculate notification dates based on reminderDaysBefore
    for (int daysBefore in reminder.reminderDaysBefore) {
      DateTime notificationDate =
          reminder.dueDate.subtract(Duration(days: daysBefore));
      DateTime notificationDateTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        reminder.reminderTime.hour,
        reminder.reminderTime.minute,
      );

      // Only schedule if the notification date is in the future
      if (notificationDateTime.isAfter(DateTime.now())) {
        print('Notification scheduled for: $notificationDateTime');
        // Here you would actually schedule the notification
        // await flutterLocalNotificationsPlugin.zonedSchedule(...)
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    // Return list of pending notifications
    // In a real app, you would get this from flutter_local_notifications
    return [];
  }

  Future<void> cancelNotification(String reminderId) async {
    // Cancel notifications for a specific reminder
    print('Cancelling notifications for reminder: $reminderId');
    // In a real app, you would cancel the notification using its ID
  }

  Future<void> cancelAllNotifications() async {
    // Cancel all notifications
    print('Cancelling all notifications');
    // In a real app, you would cancel all notifications
  }

  void checkAndShowDueNotifications() {
    // Check for due notifications and show them
    print('Checking for due notifications');
    // In a real app, you would check for notifications that should be shown now
  }

  Future<void> showTestNotification() async {
    // Show a test notification
    print('Showing test notification');
    // In a real app, you would show an immediate test notification
  }
}

class PaymentReminder {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isRecurring;
  final String repeatInterval;
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
    this.isRecurring = false,
    this.repeatInterval = 'none',
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.reminderDaysBefore = const [1, 3],
    this.priority = 'medium',
    this.notes = '',
  });

  PaymentReminder copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isRecurring,
    String? repeatInterval,
    TimeOfDay? reminderTime,
    List<int>? reminderDaysBefore,
    String? priority,
    String? notes,
  }) {
    return PaymentReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'category': category,
      'isRecurring': isRecurring,
      'repeatInterval': repeatInterval,
      'reminderTimeHour': reminderTime.hour,
      'reminderTimeMinute': reminderTime.minute,
      'reminderDaysBefore': reminderDaysBefore,
      'priority': priority,
      'notes': notes,
    };
  }

  factory PaymentReminder.fromJson(Map<String, dynamic> json) {
    return PaymentReminder(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate']),
      category: json['category'],
      isRecurring: json['isRecurring'] ?? false,
      repeatInterval: json['repeatInterval'] ?? 'none',
      reminderTime: TimeOfDay(
        hour: json['reminderTimeHour'] ?? 9,
        minute: json['reminderTimeMinute'] ?? 0,
      ),
      reminderDaysBefore: List<int>.from(json['reminderDaysBefore'] ?? [1, 3]),
      priority: json['priority'] ?? 'medium',
      notes: json['notes'] ?? '',
    );
  }
}
