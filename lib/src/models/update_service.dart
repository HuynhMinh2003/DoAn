import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceUpdate {
  final String companyId;
  final String companyName;
  final String companyType;
  final String fileLink;
  final String imageServiceUrl;
  final bool isEnable;
  final String price;
  final Timestamp timestamp;

  ServiceUpdate({
    required this.companyId,
    required this.companyName,
    required this.companyType,
    required this.fileLink,
    required this.imageServiceUrl,
    required this.isEnable,
    required this.price,
    required this.timestamp,
  });

  factory ServiceUpdate.fromFirestore({
    required String companyId,
    required String companyName,
    required String companyType,
    required DocumentSnapshot doc,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceUpdate(
      companyId: companyId,
      companyName: companyName,
      companyType: companyType,
      fileLink: data['fileLink'] ?? '',
      imageServiceUrl: data['imageServiceUrl'] ?? '',
      isEnable: data['isEnable'] ?? false,
      price: data['price'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
