import 'package:cloud_firestore/cloud_firestore.dart';

class CarDocument {
  final String id;
  final String name;
  final String url;
  final DateTime uploadDate;
  final String filePath;
  CarDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadDate,
    required this.filePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'filePath': filePath,
    };
  }

  factory CarDocument.fromFirestore(Map<String, dynamic> data, String id) {
    return CarDocument(
      id: id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      uploadDate:
          (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      filePath: data['filePath'] ?? '',
    );
  }
}
