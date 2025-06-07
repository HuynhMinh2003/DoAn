import 'package:cloud_firestore/cloud_firestore.dart';

class Information {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final List<String> seenBy;
  final DateTime timestamp;
  final DateTime? lastEdited;
  final String source; // Thêm trường này

  Information({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.seenBy,
    required this.timestamp,
    required this.lastEdited,
    required this.source,
  });

  factory Information.fromFirestore(DocumentSnapshot doc, String source) {
    final data = doc.data() as Map<String, dynamic>;
    return Information(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      seenBy: List<String>.from(data['seenBy'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      lastEdited: data['lastEdited'] != null ? (data['lastEdited'] as Timestamp).toDate() : null,
      source: source,
    );
  }
}
