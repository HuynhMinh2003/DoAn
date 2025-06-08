import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String uid;
  final String email;
  final List<String> fcmTokens;
  final String imageUrl;
  final Timestamp lastUpdated;
  final String fullName;
  final String phone;

  Admin({
    required this.uid,
    required this.email,
    required this.fcmTokens,
    required this.imageUrl,
    required this.lastUpdated,
    required this.fullName,
    required this.phone,
  });

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return Admin(
      uid: doc.id,
      email: json['email'] ?? '',
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      lastUpdated: json['lastUpdated'] != null ? json['lastUpdated'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0),
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fcmTokens': fcmTokens,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated,
      'fullName': fullName,
      'phone': phone,
    };
  }
}
