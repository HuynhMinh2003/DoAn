import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProblemHistoryScreen extends StatelessWidget {
  final String staffId;

  const ProblemHistoryScreen({super.key, required this.staffId});

  void _showIncidentDetailsDialog(BuildContext context, String incidentId) async {
    final doc = await FirebaseFirestore.instance.collection('incidents').doc(incidentId).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final handledAt = (data['handledAt'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Chi tiết sự cố'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text("Không tải được ảnh."),
                  ),
                ),
              const SizedBox(height: 12),
              _infoRow("Tòa nhà", data['building']),
              _infoRow("Căn hộ", data['apartmentAddress']),
              _infoRow("Người báo cáo", data['reporterName']),
              _infoRow("Ghi chú quản lý", data['managerNote']),
              _infoRow("Mức độ ưu tiên", data['priority']),
              if (createdAt != null)
                _infoRow("Ngày tạo", DateFormat('dd/MM/yyyy HH:mm').format(createdAt)),
              if (handledAt != null)
                _infoRow("Ngày xử lý", DateFormat('dd/MM/yyyy HH:mm').format(handledAt)),
              _infoRow("Trạng thái", data['status']),
              const SizedBox(height: 8),
              const Text("Mô tả:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['description'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Đóng"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử sự cố"),
        backgroundColor: const Color(0xFF3C4DFF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('staffs')
            .doc(staffId)
            .collection('problemHistory')
            .orderBy('responseTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("Không có lịch sử sự cố nào."));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Không rõ tiêu đề';
              final note = data['note'] ?? '';
              final proofImageUrl = data['proofImageUrl'];
              final accepted = data['accepted'] ?? false;
              final responseTime = (data['responseTime'] as Timestamp?)?.toDate();
              final incidentId = data['incidentId'] ?? '';
              final rejectionReason = data['rejectionReason'];

              return GestureDetector(
                onTap: () {
                  _showIncidentDetailsDialog(context, data['incidentId']);
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (note.isNotEmpty)
                          Text("Ghi chú: $note", style: const TextStyle(fontSize: 14)),
                        if (rejectionReason != null)
                          Text("Lý do từ chối: $rejectionReason", style: const TextStyle(fontSize: 14, color: Colors.red)),
                        if (responseTime != null)
                          Text(
                            "Thời gian phản hồi: ${DateFormat('dd/MM/yyyy HH:mm').format(responseTime)}",
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        Text(
                          "Trạng thái: ${accepted ? 'Đã hoàn thành' : 'Xử lí thất bại'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: accepted ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (proofImageUrl != null && proofImageUrl.toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              proofImageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text("Không tải được hình ảnh."),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "Không có")),
        ],
      ),
    );
  }

}
