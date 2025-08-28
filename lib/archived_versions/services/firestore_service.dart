import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payment_reminder_app/models/payment_model.dart';
import 'package:payment_reminder_app/models/spending_model.dart';
import 'package:payment_reminder_app/services/notification_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get userId => _auth.currentUser?.uid;

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  // Get a stream of payments for the current user
  Stream<QuerySnapshot> getPayments() {
    if (userId == null) throw Exception('User not logged in');
    return _db
        .collection('users')
        .doc(userId)
        .collection('payments')
        .snapshots();
  }

  // Add a new payment for the current user
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    if (userId == null) throw Exception('User not logged in');
    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('payments')
        .add(paymentData);

    if (await _areNotificationsEnabled()) {
      final payment = Payment.fromFirestore(await docRef.get());
      if (!payment.isPaid) {
        _notificationService.scheduleNotification(payment);
      }
    }
  }

  // Update a payment for the current user
  Future<void> updatePayment(
    String id,
    Map<String, dynamic> paymentData,
  ) async {
    if (userId == null) throw Exception('User not logged in');
    await _db
        .collection('users')
        .doc(userId)
        .collection('payments')
        .doc(id)
        .update(paymentData);

    if (await _areNotificationsEnabled()) {
      final payment = Payment.fromFirestore(
        await _db
            .collection('users')
            .doc(userId)
            .collection('payments')
            .doc(id)
            .get(),
      );
      if (payment.isPaid) {
        _notificationService.cancelNotification(payment.id.hashCode);
      } else {
        _notificationService.scheduleNotification(payment);
      }
    }
  }

  // Delete a payment for the current user
  Future<void> deletePayment(String id) async {
    if (userId == null) throw Exception('User not logged in');
    await _db
        .collection('users')
        .doc(userId)
        .collection('payments')
        .doc(id)
        .delete();
    _notificationService.cancelNotification(id.hashCode);
  }

  // Add a new spending entry for the current user
  Future<void> addSpending(Map<String, dynamic> spendingData) async {
    if (userId == null) throw Exception('User not logged in');
    await _db
        .collection('users')
        .doc(userId)
        .collection('spendings')
        .add(spendingData);
  }

  // Get a stream of spending for the current user for a specific day
  Stream<List<Spending>> getSpendingsForDay(DateTime date) {
    if (userId == null) throw Exception('User not logged in');

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('users')
        .doc(userId)
        .collection('spendings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Spending.fromFirestore(doc)).toList(),
        );
  }

  // Set the daily spending limit for the current user
  Future<void> setDailySpendingLimit(double limit) async {
    if (userId == null) throw Exception('User not logged in');
    await _db.collection('users').doc(userId).set({
      'dailySpendingLimit': limit,
    }, SetOptions(merge: true));
  }

  // Get the daily spending limit for the current user
  Stream<double> getDailySpendingLimit() {
    if (userId == null) throw Exception('User not logged in');
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data()!.containsKey('dailySpendingLimit')) {
        return (doc.data()!['dailySpendingLimit'] as num).toDouble();
      }
      return 0.0; // Default limit if not set
    });
  }
}
