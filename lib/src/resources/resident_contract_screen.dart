import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResidentContractSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> contractData;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  const ResidentContractSummaryScreen({
    super.key,
    required this.contractData,
    required this.joinedAt,
    required this.leftAt,
  });

  String formatDate(DateTime? date) {
    if (date == null) return 'Không rõ';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final apartmentName = contractData['apartmentName'];
    final building = contractData['building'];
    final representative = contractData['representative'];
    final startDate = (contractData['startDate'] as Timestamp).toDate();
    final endDate = (contractData['endDate'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hợp đồng dịch vụ',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '''
Bạn đang thuê hợp đồng thuê dịch vụ đi kèm tại căn hộ $apartmentName / ${building[0].toLowerCase()}${building.substring(1)} có hiệu lực từ ngày ${formatDate(startDate)} đến ${formatDate(endDate)}:

-  Người đại diện hiện tại: ${representative['fullName'] ?? 'Không rõ'}

-  Bạn được thêm vào danh sách cư dân vào ngày ${formatDate(joinedAt)}

📌 Lưu ý: Bạn không phải là người ký hợp đồng gốc. Mọi thông tin pháp lý được thực hiện qua người đại diện.
''',
          style: TextStyle(fontSize: 15.sp, height: 1.6),
        ),
      ),
    );  }
}
