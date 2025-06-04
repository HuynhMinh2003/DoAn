import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyInfo {
  final String? companyId;
  final String name;
  final String email;
  final String imageUrl;
  final String phone;
  final String type;
  final String address;
  final bool isExit;
  final List<String> fcmTokens;
  final String description;
  final Timestamp? leaveAt;
  final Timestamp? createdAt;
  final Timestamp lastUpdatedd;

  CompanyInfo({
    this.companyId,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.phone,
    required this.type,
    required this.address,
    required this.isExit,
    required this.fcmTokens,
    required this.description,
    this.leaveAt,
    this.createdAt,
    required this.lastUpdatedd,
  });

  // ✅ From Firestore map
  factory CompanyInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CompanyInfo(
      companyId: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? '',
      address: map['address'] ?? '',
      isExit: map['isExit'] ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      description: map['description'] ?? '',
      leaveAt: map['leaveAt'],
      createdAt: map['createdAt'],
      lastUpdatedd: map['lastUpdatedd'] ?? Timestamp.now(), // fallback in case of missing field
    );
  }

  // ✅ To Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'phone': phone,
      'type': type,
      'address': address,
      'isExit': isExit,
      'fcmTokens': fcmTokens,
      'description': description,
      'leaveAt': leaveAt,
      'createdAt': createdAt,
      'lastUpdatedd': lastUpdatedd,
    };
  }

  // ✅ Copy with new values
  CompanyInfo copyWith({
    String? companyId,
    String? name,
    String? email,
    String? imageUrl,
    String? phone,
    String? type,
    String? address,
    bool? isExit,
    List<String>? fcmTokens,
    String? description,
    Timestamp? leaveAt,
    Timestamp? createdAt,
    Timestamp? lastUpdatedd,
  }) {
    return CompanyInfo(
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      isExit: isExit ?? this.isExit,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      description: description ?? this.description,
      leaveAt: leaveAt ?? this.leaveAt,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedd: lastUpdatedd ?? this.lastUpdatedd,
    );
  }

  // ✅ From Firestore DocumentSnapshot
  factory CompanyInfo.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return CompanyInfo(
      companyId: doc.id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      phone: json['phone'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      isExit: json['isExit'] ?? false,
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []),
      description: json['description'] ?? '',
      leaveAt: json['leaveAt'],
      createdAt: json['createdAt'],
      lastUpdatedd: json['lastUpdatedd'] ?? Timestamp.now(),
    );
  }
}
