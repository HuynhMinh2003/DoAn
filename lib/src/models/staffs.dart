import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String uid;
  final String email;
  final List<String> fcmTokens;
  final String imageUrl;
  final bool isFree;
  final Timestamp lastUpdated;
  final String name;
  final String phone;
  final String position;
  final int role;
  final Timestamp createdAt;

  Staff({
    required this.uid,
    required this.email,
    required this.fcmTokens,
    required this.imageUrl,
    required this.isFree,
    required this.lastUpdated,
    required this.name,
    required this.phone,
    required this.position,
    required this.role,
    required this.createdAt,
  });

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return Staff(
      uid: doc.id,
      email: json['email'] ?? '',
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isFree: json['isFree'] ?? false,
      lastUpdated: json['lastUpdated'] != null ? json['lastUpdated'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0), // Nếu null, dùng giá trị mặc định
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      position: json['position'] ?? '',
      role: json['role'] ?? 0,
      createdAt: json['createdAt'] != null ? json['createdAt'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0), // Nếu null, dùng giá trị mặc định
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fcmTokens': fcmTokens,
      'imageUrl': imageUrl,
      'isFree': isFree,
      'lastUpdated': lastUpdated,
      'name': name,
      'phone': phone,
      'position': position,
      'role': role,
      'createdAt': createdAt,
    };
  }
}