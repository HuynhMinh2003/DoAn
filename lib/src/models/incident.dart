import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final String title;
  final String description;
  final String reporterId;
  final String reporterName;
  final String building;
  final String apartmentAddress;
  final String? priority;
  final String status;
  final String? imageUrl;
  final Timestamp? createdAt;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? managerNote;
  final Timestamp? handledAt;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterId,
    required this.reporterName,
    required this.building,
    required this.apartmentAddress,
    required this.status,
    this.priority,
    this.imageUrl,
    this.createdAt,
    this.assignedStaffId,
    this.assignedStaffName,
    this.managerNote,
    this.handledAt,
  });

  factory Incident.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Incident(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      building: data['building'] ?? '',
      apartmentAddress: data['apartmentAddress'] ?? '',
      priority: data['priority'],
      status: data['status'] ?? 'Đang chờ xử lý',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'],
      assignedStaffId: data['assignedStaffId'],
      assignedStaffName: data['assignedStaffName'],
      managerNote: data['managerNote'],
      handledAt: data['handledAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'building': building,
      'apartmentAddress': apartmentAddress,
      'priority': priority,
      'status': status,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'assignedStaffId': assignedStaffId,
      'assignedStaffName': assignedStaffName,
      'managerNote': managerNote,
      'handledAt': handledAt,
    };
  }
}
