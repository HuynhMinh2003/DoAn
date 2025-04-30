import 'package:do_an/src/models/resident_info.dart';

class ContractData {
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
  final String apartmentDocId; // 👈 Doc ID của căn hộ trong Firestore

  ContractData({
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
  });

  ContractData copyWith({
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
    String? apartmentDocId, // 👈 thêm tham số vào copyWith
  }) {
    return ContractData(
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
    );
  }
}


