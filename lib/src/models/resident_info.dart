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

  factory ResidentInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ResidentInfo(
      residentId: docId,
      fullName: map['fullName'] ?? '',
      cccd: map['cccd'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: _parseDate(map['birthDate']),
      email: map['email'] ?? '',
      apartmentId: map['apartmentId'],
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      // Nếu date là String, cố gắng parse thành DateTime
      try {
        return DateTime.parse(date);
      } catch (e) {
        print("Error parsing date: $e");
        return null;
      }
    }
    return null; // Trả về null nếu không phải Timestamp hoặc String
  }


  // Dùng trực tiếp khi đọc từ Firestore
  factory ResidentInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResidentInfo.fromMap(data, doc.id);
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
