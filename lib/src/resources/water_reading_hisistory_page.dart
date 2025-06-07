import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class WaterReadingHistoryScreen extends StatelessWidget {
  final String staffId;
  final String staffName;

  const WaterReadingHistoryScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context) {
    final historyRef = FirebaseFirestore.instance
        .collection('staffs')
        .doc(staffId)
        .collection('waterReadings')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch sử ghi nước',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text('Chưa có lịch sử ghi chỉ số.',style: TextStyle(fontSize: 15.sp),));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final apartment = data['apartmentName'] ?? '';
              final building = data['building'] ?? '';
              final month = data['month'] ?? '';
              final oldReading = data['oldReading'] ?? 0;
              final newReading = data['newReading'] ?? 0;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                  : 'Không rõ thời gian';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                elevation: 2,
                child: ListTile(
                  title: Text('$building / Căn $apartment',style: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.bold),),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tháng: $month',style: TextStyle(fontSize: 15.sp),),
                      SizedBox(height: 10.h,),
                      Text('Chỉ số: $oldReading → $newReading',style: TextStyle(fontSize: 15.sp),),
                      SizedBox(height: 10.h,),
                      Text('Thời gian: $formattedTime',style: TextStyle(fontSize: 15.sp),),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
