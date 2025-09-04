import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  final String id;
  final String residentName;
  final String apartmentNumber;
  final String building;
  final String serviceName;
  final String status;
  final String note;
  final String phone;
  final String requestTime;
  final Timestamp createdAt;
  final String companyId;

  ServiceRequest({
    required this.id,
    required this.residentName,
    required this.apartmentNumber,
    required this.building,
    required this.serviceName,
    required this.status,
    required this.note,
    required this.phone,
    required this.requestTime,
    required this.createdAt,
    required this.companyId,
  });

  factory ServiceRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest(
      id: doc.id,
      residentName: data['residentName'] ?? '',
      apartmentNumber: data['apartmentNumber'] ?? '',
      building: data['building'] ?? '',
      serviceName: data['serviceName'] ?? '',
      status: data['status'] ?? '',
      note: data['note'] ?? '',
      phone: data['phone'] ?? '',
      requestTime: data['requestTime'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      companyId: data['companyId'] ?? '',
    );
  }
}
