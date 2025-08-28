import 'package:cloud_firestore/cloud_firestore.dart';

class Spending {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String userId;
  final String category;

  Spending({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.userId,
    this.category = 'Others',
  });

  factory Spending.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Spending(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      category: data['category'] ?? 'Others',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'category': category,
    };
  }
}
