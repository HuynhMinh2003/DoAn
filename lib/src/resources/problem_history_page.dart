import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import '../models/problem_history.dart';

class ProblemHistoryScreen extends StatelessWidget {
  final String staffId;

  const ProblemHistoryScreen({super.key, required this.staffId});

  Future<void> _showIncidentDetailsDialog(BuildContext context, String incidentId) async {
    final doc = await FirebaseFirestore.instance.collection('incidents').doc(incidentId).get();

    if (!doc.exists) return;

    final incident = Incident.fromMap(doc.data()!, id: doc.id);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.0.h, vertical: 6.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500.w),
          child: Padding(
            padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  incident.title,
                  style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (incident.imageUrl != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              incident.imageUrl!,
                              height: 120,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text("Không tải được ảnh."),
                            ),
                          ),
                        ),
                      SizedBox(height: 12.h),
                      _infoRow("Tòa nhà", incident.building),
                      _infoRow("Căn hộ", incident.apartmentAddress),
                      _infoRow("Người báo cáo", incident.reporterName),
                      _infoRow("Ghi chú quản lý", incident.managerNote),
                      _infoRow("Mức độ ưu tiên", incident.priority),
                      if (incident.createdAt != null)
                        _infoRow("Ngày báo", DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt!.toDate())),
                      if (incident.handledAt != null)
                        _infoRow("Ngày xử lý", DateFormat('dd/MM/yyyy HH:mm').format(incident.handledAt!.toDate())),
                      _infoRow("Trạng thái", incident.status),
                      _infoRow("Mô tả", incident.description),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text("Đóng", style: TextStyle(fontSize: 13.sp)),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Lịch sử sự cố",style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp),),
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
            return Center(child: Text("Không có lịch sử sự cố nào.",style: TextStyle(fontSize: 15.sp)));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final problemHistory = ProblemHistory.fromMap(data, id: doc.id);

              return PressableCard(
                onTap: () {
                  _showIncidentDetailsDialog(context, problemHistory.incidentId);
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: problemHistory.proofImageUrl != null
                                    ? Image.network(
                                  problemHistory.proofImageUrl!,
                                  height: 100,
                                  width: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Text("Không tải được hình ảnh."),
                                )
                                    : const Text("Không có hình ảnh."),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              flex: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tên sự cố: ${problemHistory.title}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (problemHistory.responseTime != null)
                                    Text(
                                      "Thời gian phản hồi: ${DateFormat('dd/MM/yyyy HH:mm').format(problemHistory.responseTime!)}",
                                      style: TextStyle(fontSize: 12.sp),
                                    )                             ,
                                  SizedBox(height: 8.h),
                                  if (problemHistory.note.isNotEmpty)
                                    Text("Ghi chú: ${problemHistory.note}", style: TextStyle(fontSize: 12.sp)),
                                  if (problemHistory.rejectionReason != null)
                                    Text("Lý do từ chối: ${problemHistory.rejectionReason}", style: TextStyle(fontSize: 12.sp, color: Colors.red)),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Trạng thái: ${problemHistory.accepted ? 'Đã hoàn thành' : 'Xử lý thất bại'}",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: problemHistory.accepted ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12.sp)),
          Expanded(child: Text(value ?? "Không có", style: TextStyle(fontSize: 12.sp),)),
        ],
      ),
    );
  }

}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PressableCard({super.key, required this.child, required this.onTap});

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97); // thu nhỏ nhẹ khi nhấn
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0); // trở lại bình thường
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}


