import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentInfo {
  String? residentId;
  final String phone;
  final String fullName;
  final String cccd;
  final String gender;
  final String address;
  final DateTime? birthDate;
  final String email;
  final String? apartmentId;
  final String? imageUrl;
  final bool isExit;
  final DateTime? lastUpdate;
  final DateTime? leaveAt;
  final DateTime? createdAt;
  final List<String> fcmTokens;

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
    this.imageUrl,
    this.isExit = false,
    this.lastUpdate,
    this.leaveAt,
    this.createdAt,
    this.fcmTokens = const [],
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
      imageUrl: map['imageUrl'],
      isExit: map['isExit'] ?? false,
      lastUpdate: _parseDate(map['lastUpdate']),
      leaveAt: _parseDate(map['leaveAt']),
      createdAt: _parseDate(map['createdAt']),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
    );
  }

  factory ResidentInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResidentInfo.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'apartmentId': apartmentId,
      'cccd': cccd,
      'email': email,
      'gender': gender,
      'address': address,
      'fcmTokens': fcmTokens,
      'fullName': fullName,
      'phone': phone,
      'role': 3,
      'isExit': isExit,
      // dùng server time cho lần cập nhật cuối
      'lastUpdate': FieldValue.serverTimestamp(),
    };

    // ngày sinh
    data['birthDate'] = Timestamp.fromDate(birthDate!);

    // createdAt chỉ set lần đầu nếu chưa có
    if (createdAt != null) {
      data['createdAt'] = Timestamp.fromDate(createdAt!);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    if (leaveAt != null) {
      data['leaveAt'] = Timestamp.fromDate(leaveAt!);
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      data['imageUrl'] = imageUrl;
    }

    return data;
  }


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
    String? imageUrl,
    bool? isExit,
    DateTime? lastUpdate,
    DateTime? leaveAt,
    DateTime? createdAt,
    List<String>? fcmTokens,
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
      imageUrl: imageUrl ?? this.imageUrl,
      isExit: isExit ?? this.isExit,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      leaveAt: leaveAt ?? this.leaveAt,
      createdAt: createdAt ?? this.createdAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        print("Error parsing date: $e");
        return null;
      }
    }
    return null;
  }
}
