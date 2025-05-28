import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateService {
  final String id;
  final String imageUrl;
  final String price;
  final String fileLink;
  final bool isEnable;
  final Timestamp? timestamp;

  UpdateService({
    required this.id,
    required this.imageUrl,
    required this.price,
    required this.fileLink,
    required this.isEnable,
    required this.timestamp,
  });

  factory UpdateService.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UpdateService(
      id: doc.id,
      imageUrl: data['imageServiceUrl'] ?? '',
      price: data['price'] ?? '',
      fileLink: data['fileLink'] ?? '',
      isEnable: data['isEnable'] ?? false,
      timestamp: data['timestamp'],
    );
  }
}
