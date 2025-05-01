import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/resident_info.dart';

class ContractData {
  final String? contractId;
  final String apartmentName;
  final String building;
  final double area;
  final int rentPrice;
  final int salePrice;
  final String contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final int numberOfResidents;
  final List<ResidentInfo> residents;
  final String apartmentDocId;
  final String? representative; // Thêm representative

  ContractData({
    this.contractId,
    required this.apartmentName,
    required this.building,
    required this.area,
    required this.rentPrice,
    required this.salePrice,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.numberOfResidents,
    required this.residents,
    required this.apartmentDocId,
    this.representative,  // Thêm representative vào constructor
  });

  ContractData copyWith({
    String? contractId,
    String? apartmentName,
    String? building,
    double? area,
    int? rentPrice,
    int? salePrice,
    String? contractType,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfResidents,
    List<ResidentInfo>? residents,
    String? apartmentDocId,
    String? representative, // Thêm representative vào copyWith
  }) {
    return ContractData(
      contractId: contractId ?? this.contractId,
      apartmentName: apartmentName ?? this.apartmentName,
      building: building ?? this.building,
      area: area ?? this.area,
      rentPrice: rentPrice ?? this.rentPrice,
      salePrice: salePrice ?? this.salePrice,
      contractType: contractType ?? this.contractType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfResidents: numberOfResidents ?? this.numberOfResidents,
      residents: residents ?? this.residents,
      apartmentDocId: apartmentDocId ?? this.apartmentDocId,
      representative: representative ?? this.representative,  // Thêm representative vào copyWith
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "contractId": contractId,
      "apartmentDocId": apartmentDocId,
      "apartmentName": apartmentName,
      "building": building,
      "area": area,
      "price": contractType == "rent" ? rentPrice : salePrice,
      "type": contractType,
      "startDate": startDate,
      "endDate": endDate,
      "numberOfResidents": numberOfResidents,
      "representative": representative,  // Thêm representative vào map
      "createdAt": Timestamp.now(),
    };
  }

  factory ContractData.fromMap(Map<String, dynamic> map, String docId, List<ResidentInfo> residents) {
    return ContractData(
      contractId: docId,
      apartmentDocId: map['apartmentDocId'] ?? '',
      apartmentName: map['apartmentName'] ?? '',
      building: map['building'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      rentPrice: map['type'] == 'rent' ? map['price'] ?? 0 : 0,
      salePrice: map['type'] == 'sale' ? map['price'] ?? 0 : 0,
      contractType: map['type'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      numberOfResidents: map['numberOfResidents'] ?? 0,
      residents: residents,
      representative: map['representative'] ?? '', // Thêm representative vào từ Firestore
    );
  }
}
