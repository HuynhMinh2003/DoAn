import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/resident_summary.dart';

class Apartment {
  final String id;
  final String apartmentName;
  final String building;
  final String currentContractId;
  final int area;
  final String description;
  final List<ResidentSummary> residents;
  final String status;

  Apartment({
    required this.id,
    required this.apartmentName,
    required this.building,
    required this.currentContractId,
    required this.area,
    required this.description,
    required this.residents,
    required this.status,
  });

  factory Apartment.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Apartment(
      id: doc.id,
      apartmentName: json['apartmentName'],
      building: json['building'],
      currentContractId: json['currentContractId']??'',
      area: json['area'],
      description: json['description'],
      residents: (json['residents'] as List<dynamic>?)
          ?.map((e) => ResidentSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apartmentName': apartmentName,
      'building': building,
      'currentContractId': currentContractId,
      'area': area,
      'description': description,
      'residents': residents.map((e) => e.toJson()).toList(),
      'status': status
    };
  }

  int get floor {
    return int.parse(apartmentName.split('-').first);
  }
}
