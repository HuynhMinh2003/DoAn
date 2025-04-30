import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentInfo {
  final String? residentId; // nullable
  final String fullName;
  final String cccd;
  final String phone;
  final DateTime birthDate;
  final String email;

  ResidentInfo({
    this.residentId,
    required this.fullName,
    required this.cccd,
    required this.phone,
    required this.birthDate,
    required this.email,
  });

  factory ResidentInfo.fromMap(Map<String, dynamic> map, String docId) {
    return ResidentInfo(
      residentId: docId, // lấy từ document ID
      fullName: map['name'] ?? '',
      cccd: map['cccd'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Không nên lưu residentId vào trong map, vì nó là doc ID
      'name': fullName,
      'cccd': cccd,
      'phone': phone,
      'birthDate': birthDate,
      'email': email,
    };
  }
}
