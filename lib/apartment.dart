// 1. Model căn hộ
class Apartment {
  final String apartmentName;
  final String building;
  final int area;
  final int rentPrice;
  final int salePrice;
  final String description;
  final bool isRent;
  final bool isSale;

  Apartment({
    required this.apartmentName,
    required this.building,
    required this.area,
    required this.rentPrice,
    required this.salePrice,
    required this.description,
    required this.isRent,
    required this.isSale,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      apartmentName: json['apartmentName'],
      building: json['building'],
      area: json['area'],
      rentPrice: json['rentPrice'],
      salePrice: json['salePrice'],
      description: json['description'],
      isRent: json['isRent'],
      isSale: json['isSale'],
    );
  }

  int get floor {
    // Lấy số tầng từ apartmentName (ví dụ "7-12" => floor = 7)
    return int.parse(apartmentName.split('-').first);
  }
}
