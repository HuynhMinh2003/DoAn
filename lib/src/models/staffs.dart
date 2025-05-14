import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String uid;
  final String email;
  final List<String> fcmTokens;
  final String imageUrl;
  final bool isFree;
  final DateTime? birthDate;
  final Timestamp lastUpdated;
  final String fullName;
  final String phone;
  final String cccd;
  final String address;
  final String position;
  final String gender;
  final int role;
  final Timestamp createdAt;
  final bool isExit; // Thêm trường isExit

  Staff({
    required this.uid,
    required this.email,
    required this.fcmTokens,
    required this.imageUrl,
    required this.isFree,
    this.birthDate,
    required this.lastUpdated,
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.address,
    required this.position,
    required this.gender,
    required this.role,
    required this.createdAt,
    required this.isExit, // Thêm isExit vào constructor
  });

  /// Factory method to create a Staff object from Firestore data.
  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return Staff(
      uid: doc.id,
      email: json['email'] ?? '',
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isFree: json['isFree'] ?? false,
      birthDate: json['birthDate'] != null ? (json['birthDate'] as Timestamp).toDate() : null, // Convert Timestamp to DateTime
      lastUpdated: json['lastUpdated'] != null ? json['lastUpdated'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0), // Default value if null
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      cccd: json['cccd'] ?? '',
      address: json['address'] ?? '',
      position: json['position'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? 0,
      createdAt: json['createdAt'] != null ? json['createdAt'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0), // Default value if null
      isExit: json['isExit'] ?? false, // Thêm isExit vào factory method
    );
  }

  /// Converts the Staff object into a JSON representation for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fcmTokens': fcmTokens,
      'imageUrl': imageUrl,
      'isFree': isFree,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null, // Convert DateTime to Timestamp
      'lastUpdated': lastUpdated,
      'fullName': fullName,
      'phone': phone,
      'cccd': cccd,
      'address': address,
      'position': position,
      'gender': gender,
      'role': role,
      'createdAt': createdAt,
      'isExit': isExit, // Thêm isExit vào toJson method
    };
  }
}