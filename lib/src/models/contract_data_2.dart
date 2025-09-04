import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/resident_info.dart';

class ContractData2 {
  final String? contractId;
  final String apartmentName;
  final String building;
  final double area;
  final int rentPrice;
  final int salePrice;
  final String contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime timepay;
  final int numberOfResidents;
  final List<ResidentInfo> residents;
  final String apartmentDocId;
  final Map<String, String>? representative;
  final String? purpose;
  final String? devices;
  final String? limit;
  final int? price;
  final String? timepayattention;

  ContractData2({
    this.contractId,
    required this.apartmentName,
    required this.building,
    required this.area,
    required this.rentPrice,
    required this.salePrice,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.timepay,
    required this.numberOfResidents,
    required this.residents,
    required this.apartmentDocId,
    this.representative,
    this.purpose,
    this.devices,
    this.limit,
    this.price,
    this.timepayattention,
  });

  ContractData2 copyWith({
    String? contractId,
    String? apartmentName,
    String? building,
    double? area,
    int? rentPrice,
    int? salePrice,
    String? contractType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? timepay,
    int? numberOfResidents,
    List<ResidentInfo>? residents,
    String? apartmentDocId,
    Map<String, String>? representative,
    String? purpose,
    String? devices,
    String? limit,
    int? price,
    String? timepayattention,
  }) {
    return ContractData2(
      contractId: contractId ?? this.contractId,
      apartmentName: apartmentName ?? this.apartmentName,
      building: building ?? this.building,
      area: area ?? this.area,
      rentPrice: rentPrice ?? this.rentPrice,
      salePrice: salePrice ?? this.salePrice,
      contractType: contractType ?? this.contractType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timepay: timepay ?? this.timepay,
      numberOfResidents: numberOfResidents ?? this.numberOfResidents,
      residents: residents ?? this.residents,
      apartmentDocId: apartmentDocId ?? this.apartmentDocId,
      representative: representative ?? this.representative,
      purpose: purpose ?? this.purpose,
      devices: devices ?? this.devices,
      limit: limit ?? this.limit,
      price: price ?? this.price,
      timepayattention: timepayattention ?? this.timepayattention,
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
      "timepay": timepay,
      "numberOfResidents": numberOfResidents,
      "representative": representative,
      "purpose": purpose,
      "devices": devices,
      "limit": limit,
      "price": price,
      "timepayattention": timepayattention,
      "createdAt": Timestamp.now(),
    };
  }

  factory ContractData2.fromMap(Map<String, dynamic> map, String docId, List<ResidentInfo> residents) {
    return ContractData2(
      contractId: docId,
      apartmentDocId: map['apartmentDocId'] ?? '',
      apartmentName: map['apartmentName'] ?? '',
      building: map['building'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      rentPrice: map['type'] == 'rent' ? map['price'] ?? 0 : 0,
      salePrice: map['type'] == 'sale' ? map['price'] ?? 0 : 0,
      contractType: map['type'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      timepay: (map['timepay'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      numberOfResidents: map['numberOfResidents'] ?? 0,
      residents: residents,
      representative: map['representative'] != null
          ? Map<String, String>.from(map['representative'])
          : null,
      purpose: map['purpose'],
      devices: map['devices'],
      limit: map['limit'],
      price: map['price'],
      timepayattention: map['timepayattention'],
    );
  }

}
