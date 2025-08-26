import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String category;
  final String repeat;
  final bool isPaid;

  Payment({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.repeat,
    required this.isPaid,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      category: data['category'] ?? 'other',
      repeat: data['repeat'] ?? 'none',
      isPaid: data['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'category': category,
      'repeat': repeat,
      'isPaid': isPaid,
    };
  }

  Payment copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? category,
    String? repeat,
    bool? isPaid,
  }) {
    return Payment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      repeat: repeat ?? this.repeat,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
