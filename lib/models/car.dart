import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String make;
  final String model;
  final String vin;
  final String licensePlate;
  final DateTime? annualTax;
  final DateTime? insurance;
  final DateTime? nextServiceInterval;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.vin,
    required this.licensePlate,
    this.annualTax,
    this.insurance,
    this.nextServiceInterval,
  });

  // Add the copyWith method here
  Car copyWith({
    String? id,
    String? make,
    String? model,
    String? vin,
    String? licensePlate,
    DateTime? annualTax,
    DateTime? insurance,
    DateTime? nextServiceInterval,
  }) {
    return Car(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      annualTax: annualTax ?? this.annualTax,
      insurance: insurance ?? this.insurance,
      nextServiceInterval: nextServiceInterval ?? this.nextServiceInterval,
    );
  }

  factory Car.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Car(
      id: documentId,
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      vin: data['vin'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      annualTax: data['annualTax']?.toDate(),
      insurance: data['insurance']?.toDate(),
      nextServiceInterval: data['nextServiceInterval']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'vin': vin,
      'licensePlate': licensePlate,
      'annualTax': annualTax != null ? Timestamp.fromDate(annualTax!) : null,
      'insurance': insurance != null ? Timestamp.fromDate(insurance!) : null,
      'nextServiceInterval': nextServiceInterval != null
          ? Timestamp.fromDate(nextServiceInterval!)
          : null,
    };
  }
}