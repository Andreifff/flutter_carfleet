import 'package:cloud_firestore/cloud_firestore.dart';

class Spending {
  final String category;
  final double amount;
  final int odometer;
  final String currency;
  final DateTime date;

  Spending(
      {required this.category,
      required this.amount,
      required this.odometer,
      required this.currency,
      required this.date});

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'odometer': odometer,
      'currency': currency,
      'date': date,
    };
  }

  factory Spending.fromFirestore(Map<String, dynamic> data) => Spending(
        category: data['category'] ?? '',
        amount: data['amount'] ?? 0.0,
        odometer: data['odometer'] ?? 0,
        date: (data['date'] as Timestamp).toDate(),
        currency: data['currency'] ?? '',
      );
}
