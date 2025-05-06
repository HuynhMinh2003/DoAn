import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentInfo {
  String? residentId; // optional, nếu lấy từ Firestore thì có
  final String fullName;
  final String cccd;
  final String phone;
  final DateTime? birthDate;
  final String email;
  final String? apartmentId; // Thêm apartmentId

  ResidentInfo({
    this.residentId,
    required this.fullName,
    required this.cccd,
    required this.phone,
    this.birthDate,
    required this.email,
    this.apartmentId,
  });

  // Tạo từ Firestore, có docId (thường dùng khi lấy từ collection)
  factory ResidentInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ResidentInfo(
      residentId: docId,
      fullName: map['name'] ?? '',
      cccd: map['cccd'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      email: map['email'] ?? '',
      apartmentId: map['apartmentId'], // Lấy apartmentId
    );
  }

  // Convert thành Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'apartmentId': apartmentId,
      'birthDate': birthDate,
      'cccd': cccd,
      'creatAt': DateTime.now(),
      'email': email,
      'fcmTokens': [],
      'fullName': fullName,
      'phone': phone,
      'role': 3
    };
  }

  // Tạo bản sao với các giá trị mới
  ResidentInfo copyWith({
    String? residentId,
    String? fullName,
    String? cccd,
    String? phone,
    DateTime? birthDate,
    String? email,
    String? apartmentId,
  }) {
    return ResidentInfo(
      residentId: residentId ?? this.residentId,
      fullName: fullName ?? this.fullName,
      cccd: cccd ?? this.cccd,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      apartmentId: apartmentId ?? this.apartmentId,
    );
  }
}
