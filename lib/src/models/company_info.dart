import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyInfo {
  final String? companyId; // Optional, if fetched from Firestore
  final String name;
  final String email;
  final String imageUrl;
  final String phone;
  final String type;
  final String address;
  final List<String> fcmTokens;
  final String description;

  CompanyInfo({
    this.companyId,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.phone,
    required this.type,
    required this.address,
    required this.fcmTokens,
    required this.description,
  });

  // Create an instance from Firestore data
  factory CompanyInfo.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CompanyInfo(
      companyId: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? '',
      address: map['address'] ?? '',
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []), // Corrected to handle List<String>
      description: map['description'] ?? '',
    );
  }

  // Convert the instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'phone': phone,
      'type': type,
      'address': address,
      'fcmTokens': fcmTokens, // Added fcmTokens
      'description': description,
    };
  }

  // Create a copy of the instance with optional new values
  CompanyInfo copyWith({
    String? companyId,
    String? name,
    String? email,
    String? imageUrl,
    String? phone,
    String? type,
    String? address,
    List<String>? fcmTokens, // Added fcmTokens
    String? description,
  }) {
    return CompanyInfo(
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      description: description ?? this.description,
    );
  }

  // Create an instance from a Firestore DocumentSnapshot
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
      fcmTokens: List<String>.from(json['fcmTokens'] ?? []), // Correctly handles List<String>
      description: json['description'] ?? '',
    );
  }
}