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
  final bool isExit;
  final Timestamp? leaveAt; // 👉 Thêm leaveAt

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
    required this.isExit,
    this.leaveAt, // 👉 Constructor
  });

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return Staff(
      uid: doc.id,
      email: json['email'] ?? '',
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isFree: json['isFree'] ?? false,
      birthDate: json['birthDate'] != null ? (json['birthDate'] as Timestamp).toDate() : null,
      lastUpdated: json['lastUpdated'] != null ? json['lastUpdated'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0),
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      cccd: json['cccd'] ?? '',
      address: json['address'] ?? '',
      position: json['position'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? 0,
      createdAt: json['createdAt'] != null ? json['createdAt'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(0),
      isExit: json['isExit'] ?? false,
      leaveAt: json['leaveAt'] != null ? json['leaveAt'] as Timestamp : null, // 👉
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fcmTokens': fcmTokens,
      'imageUrl': imageUrl,
      'isFree': isFree,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'lastUpdated': lastUpdated,
      'fullName': fullName,
      'phone': phone,
      'cccd': cccd,
      'address': address,
      'position': position,
      'gender': gender,
      'role': role,
      'createdAt': createdAt,
      'isExit': isExit,
      'leaveAt': leaveAt, // 👉 Thêm vào Firestore
    };
  }
}
