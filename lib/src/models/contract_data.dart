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
  final DateTime? timepay;
  final int numberOfResidents;
  final List<ResidentInfo> residents;
  final String apartmentDocId;
  final Map<String, String>? representative; // representative là đối tượng có cả tên và id
  final String? purpose;  // purpose của hợp đồng
  final String? devices;  // devices trong hợp đồng
  final String? limit;    // limit của hợp đồng
  final int? price;       // giá của hợp đồng
  final String? obligation;  // nghĩa vụ của bên thuê
  final String? duties;  // nghĩa vụ của bên thuê
  final String? benefit;     // quyền lợi của bên thuê
  final String? commit;
  final String? timepayattention;
  final DateTime createdAt; // Thêm trường createdAt kiểu DateTime

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
    this.timepay,
    required this.numberOfResidents,
    required this.residents,
    required this.apartmentDocId,
    this.representative,
    this.purpose,
    this.devices,
    this.limit,
    this.price,
    this.obligation,
    this.duties,
    this.benefit,
    this.commit,
    this.timepayattention,
    required this.createdAt, // Bắt buộc truyền createdAt
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
    DateTime? timepay,
    int? numberOfResidents,
    List<ResidentInfo>? residents,
    String? apartmentDocId,
    Map<String, String>? representative,
    String? purpose,
    String? devices,
    String? limit,
    int? price,
    String? obligation,
    String? duties,
    String? benefit,
    String? commit,
    String? timepayattenion,
    DateTime? createdAt, // Thêm createdAt vào copyWith
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
      timepay: timepay ?? this.timepay,
      numberOfResidents: numberOfResidents ?? this.numberOfResidents,
      residents: residents ?? this.residents,
      apartmentDocId: apartmentDocId ?? this.apartmentDocId,
      representative: representative ?? this.representative,
      purpose: purpose ?? this.purpose,
      devices: devices ?? this.devices,
      limit: limit ?? this.limit,
      price: price ?? this.price,
      obligation: obligation ?? this.obligation,
      duties: duties ?? this.duties,
      benefit: benefit ?? this.benefit,
      commit: commit ?? this.commit,
      timepayattention: timepayattention ?? this.timepayattention,
      createdAt: createdAt ?? this.createdAt, // Bổ sung createdAt
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
      "representative": representative, // Thêm representative vào map
      "purpose": purpose,
      "devices": devices,
      "limit": limit,
      "price": price,
      "obligation": obligation,
      "duties": duties,
      "benefit": benefit,
      "commit": commit,
      "timepayattention": timepayattention,
      "createdAt": Timestamp.fromDate(createdAt), // Chuyển đổi DateTime sang Timestamp
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
      timepay: map['timepay'] != null ? (map['timepay'] as Timestamp).toDate() : null,
      numberOfResidents: map['numberOfResidents'] ?? 0,
      residents: residents,
      representative: map['representative'] != null
          ? Map<String, String>.from(map['representative'])
          : null,
      purpose: map['purpose'],
      devices: map['devices'],
      limit: map['limit'],
      price: map['price'],
      obligation: map['obligation'],
      duties: map['duties'],
      benefit: map['benefit'],
      commit: map['commit'],
      timepayattention: map['timepayattention'],
      createdAt: (map['createdAt'] as Timestamp).toDate(), // Chuyển đổi Timestamp sang DateTime
    );
  }
}