class ContractData {
  final String apartmentName;
  final String building;
  final double area;
  final int rentPrice;
  final int salePrice;
  final String contractType; // 'rent' hoặc 'sale'
  final DateTime startDate;
  final DateTime? endDate;
  final int numberOfResidents;
  final List<ResidentInfo> residents;

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
    );
  }
}

class ResidentInfo {
  final String fullName;
  final String cccd;
  final String phone;
  final DateTime birthDate;
  final String email;

  ResidentInfo({
    required this.fullName,
    required this.cccd,
    required this.phone,
    required this.birthDate,
    required this.email,
  });
}
