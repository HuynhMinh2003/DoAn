import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentInfo {
  String? residentId; // optional, nếu lấy từ Firestore thì có
  final String phone;
  final String fullName;
  final String cccd;
  final String gender;
  final String address;
  final DateTime? birthDate;
  final String email;
  final String? apartmentId; // Thêm apartmentId
  final String? imageUrl; // Thêm imageUrl

  ResidentInfo({
    this.residentId,
    required this.fullName,
    required this.cccd,
    required this.phone,
    required this.gender,
    required this.address,
    this.birthDate,
    required this.email,
    this.apartmentId,
    this.imageUrl, // Khởi tạo imageUrl
  });

  factory ResidentInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ResidentInfo(
      residentId: docId,
      fullName: map['fullName'] ?? '',
      cccd: map['cccd'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      birthDate: _parseDate(map['birthDate']),
      email: map['email'] ?? '',
      apartmentId: map['apartmentId'],
      imageUrl: map['imageUrl'], // Lấy imageUrl từ map
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
      'createdAt': DateTime.now(),
      'email': email,
      'gender': gender,
      'address': address,
      'fcmTokens': [],
      'fullName': fullName,
      'phone': phone,
      'role': 3,
      'imageUrl': imageUrl, // Thêm imageUrl vào Map
    };
  }

  // Tạo bản sao với các giá trị mới
  ResidentInfo copyWith({
    String? residentId,
    String? fullName,
    String? cccd,
    String? phone,
    String? gender,
    String? address,
    DateTime? birthDate,
    String? email,
    String? apartmentId,
    String? imageUrl, // Thêm imageUrl vào phương thức copyWith
  }) {
    return ResidentInfo(
      residentId: residentId ?? this.residentId,
      fullName: fullName ?? this.fullName,
      cccd: cccd ?? this.cccd,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      apartmentId: apartmentId ?? this.apartmentId,
      imageUrl: imageUrl ?? this.imageUrl, // Sao chép imageUrl
    );
  }
}