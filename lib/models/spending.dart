import 'package:cloud_firestore/cloud_firestore.dart';

class Spending {
  String id;
  final String category;
  final double amount;
  final int odometer;
  final String currency;
  final DateTime date;
  double? convertedAmount;

  Spending({
    this.id = '',
    required this.category,
    required this.amount,
    required this.odometer,
    required this.currency,
    required this.date,
    this.convertedAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'odometer': odometer,
      'currency': currency,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Spending.fromFirestore(Map<String, dynamic> data, String id) {
    return Spending(
      id: id,
      category: data['category'] ?? '',
      amount: data['amount'] ?? 0.0,
      odometer: data['odometer'] ?? 0,
      currency: data['currency'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
