import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/resident_info.dart';

class ContractData {
  final String? contractId;
  final String apartmentName;
  final String building;
  final double area;
  final DateTime startDate;
  final DateTime? endDate;
  final int numberOfResidents;
  final List<ResidentInfo> residents;
  final String apartmentDocId;
  final Map<String, String>? representative;
  final String? purpose;
  final DateTime createdAt;
  final bool isActive;

  ContractData({
    this.contractId,
    required this.apartmentName,
    required this.building,
    required this.area,
    required this.startDate,
    this.endDate,
    required this.numberOfResidents,
    required this.residents,
    required this.apartmentDocId,
    this.representative,
    this.purpose,
    required this.createdAt,
    this.isActive = true,
  });

  ContractData copyWith({
    String? contractId,
    String? apartmentName,
    String? building,
    double? area,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfResidents,
    List<ResidentInfo>? residents,
    String? apartmentDocId,
    Map<String, String>? representative,
    String? purpose,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ContractData(
      contractId: contractId ?? this.contractId,
      apartmentName: apartmentName ?? this.apartmentName,
      building: building ?? this.building,
      area: area ?? this.area,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfResidents: numberOfResidents ?? this.numberOfResidents,
      residents: residents ?? this.residents,
      apartmentDocId: apartmentDocId ?? this.apartmentDocId,
      representative: representative ?? this.representative,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "contractId": contractId,
      "apartmentDocId": apartmentDocId,
      "apartmentName": apartmentName,
      "building": building,
      "area": area,
      "startDate": startDate,
      "endDate": endDate,
      "numberOfResidents": numberOfResidents,
      "representative": representative,
      "purpose": purpose,
      "createdAt": Timestamp.fromDate(createdAt),
      "isActive": isActive,
    };
  }

  factory ContractData.fromMap(Map<String, dynamic> map, String docId, List<ResidentInfo> residents) {
    return ContractData(
      contractId: docId,
      apartmentDocId: map['apartmentDocId'] ?? '',
      apartmentName: map['apartmentName'] ?? '',
      building: map['building'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      numberOfResidents: map['numberOfResidents'] ?? 0,
      residents: residents,
      representative: map['representative'] != null
          ? Map<String, String>.from(
        (map['representative'] as Map).map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
      )
          : null,
      purpose: map['purpose'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
