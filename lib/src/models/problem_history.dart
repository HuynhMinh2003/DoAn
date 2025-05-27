import 'package:cloud_firestore/cloud_firestore.dart';

class ProblemHistory {
  final String id; // doc id
  final String incidentId;
  final String title;
  final String note;
  final String? proofImageUrl;
  final bool accepted;
  final DateTime? responseTime;
  final String? rejectionReason;

  ProblemHistory({
    required this.id,
    required this.incidentId,
    required this.title,
    required this.note,
    this.proofImageUrl,
    required this.accepted,
    this.responseTime,
    this.rejectionReason,
  });

  factory ProblemHistory.fromMap(Map<String, dynamic> data, {required String id}) {
    return ProblemHistory(
      id: id,
      incidentId: data['incidentId'] ?? '',
      title: data['title'] ?? 'Không rõ tiêu đề',
      note: data['note'] ?? '',
      proofImageUrl: data['proofImageUrl'],
      accepted: data['accepted'] ?? false,
      responseTime: (data['responseTime'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'title': title,
      'note': note,
      'proofImageUrl': proofImageUrl,
      'accepted': accepted,
      'responseTime': responseTime != null ? Timestamp.fromDate(responseTime!) : null,
      'rejectionReason': rejectionReason,
    };
  }
}
