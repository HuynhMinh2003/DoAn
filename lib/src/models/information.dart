import 'package:cloud_firestore/cloud_firestore.dart';

class Information {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final List<String> seenBy;
  final DateTime timestamp;

  Information({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.seenBy,
    required this.timestamp,
  });

  factory Information.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Information(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      seenBy: List<String>.from(data['seenBy'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
