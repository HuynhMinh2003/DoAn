import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentSummary {
  final String id;
  final String fullName;

  ResidentSummary({required this.id, required this.fullName});

  factory ResidentSummary.fromJson(Map<String, dynamic> json) {
    return ResidentSummary(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
    };
  }
}


class Apartment {
  final String id;
  final String apartmentName;
  final String building;
  final int area;
  final int rentPrice;
  final int salePrice;
  final String description;
  final bool isRent;
  final bool isSale;
  final List<ResidentSummary> residents;

  Apartment({
    required this.id,
    required this.apartmentName,
    required this.building,
    required this.area,
    required this.rentPrice,
    required this.salePrice,
    required this.description,
    required this.isRent,
    required this.isSale,
    required this.residents,
  });

  factory Apartment.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Apartment(
      id: doc.id,
      apartmentName: json['apartmentName'],
      building: json['building'],
      area: json['area'],
      rentPrice: json['rentPrice'],
      salePrice: json['salePrice'],
      description: json['description'],
      isRent: json['isRent'],
      isSale: json['isSale'],
      residents: (json['residents'] as List<dynamic>?)
          ?.map((e) => ResidentSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apartmentName': apartmentName,
      'building': building,
      'area': area,
      'rentPrice': rentPrice,
      'salePrice': salePrice,
      'description': description,
      'isRent': isRent,
      'isSale': isSale,
      'residents': residents.map((e) => e.toJson()).toList(),
    };
  }

  int get floor {
    return int.parse(apartmentName.split('-').first);
  }
}
