import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentFiles extends StatefulWidget {
  const RecentFiles({Key? key}) : super(key: key);

  @override
  State<RecentFiles> createState() => _RecentFilesState();
}

class _RecentFilesState extends State<RecentFiles> {
  String selectedTable = 'resident';
  String? selectedContractId;

  final Map<String, String> _vehicleTypeMap = {
    'motorbike_roofed': 'Xe máy (có mái che)',
    'motorbike_unroofed': 'Xe máy (không mái che)',
    'bike_roofed': 'Xe đạp (có mái che)',
    'bike_unroofed': 'Xe đạp (không mái che)',
    'car_roofed': 'Ô tô (có mái che)',
    'car_unroofed': 'Ô tô (không mái che)',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thống kê khác",
            style: TextStyle(fontSize: 4.sp),
          ),
          SizedBox(height: 16.h),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  spreadRadius: -2, // giảm lan ra mọi hướng
                  offset: Offset(0, 1), // chỉ đổ bóng xuống
                ),
              ],
            ),
            child: CupertinoSlidingSegmentedControl<String>(
              backgroundColor: bgColor, // màu nền control
              thumbColor: secondaryColor,             // màu tab được chọn
              groupValue: selectedTable,
              children: {
                'resident': _buildSegmentItem("Thông báo cư dân"),
                'staff': _buildSegmentItem("Thông báo nhân viên"),
                'company': _buildSegmentItem("Thông báo công ty"),
                'parking': _buildSegmentItem("Thông báo đăng ký xe"),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedTable = value;
                  });
                }
              },
            ),
          ),

          SizedBox(height: 16.h),

          SizedBox(
            height: 280.h,
            width: double.infinity,
            child: _buildTableByType(selectedTable),
          ),
        ],
      ),
    );
  }

  Widget _buildTableByType(String type) {
    if (type == 'parking') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('parkingRegistrations')
            .orderBy('registeredAt', descending: true)
            .limit(4)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Lỗi: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 280.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Chưa có dữ liệu đăng ký xe',
                style: TextStyle(fontSize: 4.sp),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 40.0,
                    columns: const [
                      DataColumn(label: Text("Biển số xe")),
                      DataColumn(label: Text("Loại xe")),
                      DataColumn(label: Text("Thời gian đăng ký")),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final licensePlate = data['licensePlate'] is String
                          ? data['licensePlate'] as String
                          : '';
                      final vehicleTypeKey = data['vehicleType'] as String? ?? '';
                      final vehicleType = _vehicleTypeMap[vehicleTypeKey] ?? 'Không xác định';
                      final timestampRaw = data['registeredAt'];
                      final registeredAt = (timestampRaw is Timestamp)
                          ? _formatTimestamp(timestampRaw)
                          : 'Chưa có thời gian';

                      return DataRow(cells: [
                        DataCell(Text(licensePlate)),
                        DataCell(Text(vehicleType)),
                        DataCell(Text(registeredAt)),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      final collectionName = {
        'resident': 'information_residents',
        'staff': 'information_staffs',
        'company': 'information_companies',
      }[type]!;

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .limit(4)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Lỗi: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 280.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('Chưa có dữ liệu thông báo',style: TextStyle(fontSize: 4.sp),),);

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 40.0,
                    columns: const [
                      DataColumn(label: Text("Tiêu đề")),
                      DataColumn(label: Text("Thời gian đăng")),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final title = data['title'] is String ? data['title'] as String : '';
                      final timestampRaw = data['timestamp'];
                      final timeStr = (timestampRaw is Timestamp)
                          ? _formatTimestamp(timestampRaw)
                          : 'Chưa có thời gian';

                      return DataRow(cells: [
                        DataCell(Text(title)),
                        DataCell(Text(timeStr)),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSegmentItem(String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      alignment: Alignment.center,
      width: 100.w, // bạn có thể chỉnh width tùy theo tổng số tab hoặc screen size
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 4.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

}
