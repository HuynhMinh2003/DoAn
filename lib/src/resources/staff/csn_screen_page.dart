import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CSNScreenPage extends StatefulWidget {
  final String contractId;

  const CSNScreenPage({super.key, required this.contractId});

  @override
  State<CSNScreenPage> createState() => _CSNScreenPageState();
}

class _CSNScreenPageState extends State<CSNScreenPage> {
  int _selectedTab = 0;

  Map<String, dynamic>? currentWaterReading;
  List<Map<String, dynamic>> waterHistory = [];

  @override
  void initState() {
    super.initState();
    loadWaterReadingData();
  }

  Future<void> loadWaterReadingData() async {
    final now = DateTime.now();
    final formattedMonth = DateFormat('MM-yyyy').format(now);
    final currentDoc = await FirebaseFirestore.instance
        .collection("contracts")
        .doc(widget.contractId)
        .collection("waterReadings")
        .doc(formattedMonth.replaceAll("/", "-"))
        .get();

    currentWaterReading = currentDoc.data();

    final historyQuery = await FirebaseFirestore.instance
        .collection("contracts")
        .doc(widget.contractId)
        .collection("waterReadings")
        .orderBy("timestamp", descending: true)
        .get();

    waterHistory = historyQuery.docs.map((doc) => {
      ...doc.data(),
      'month': doc.id
    }).toList();

    setState(() {});
  }

  Widget _buildTabButton(String label, int index, bool isActive) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black,
      ),
      child: Text(label, style: TextStyle(fontSize: 15.sp)),
    );
  }

  Widget _buildCurrentWaterTab() {
    if (currentWaterReading == null) {
      return Center(child: Text("Không có dữ liệu chỉ số nước tháng này."));
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 12.h),
          Column(
            children: [
              Text("Chỉ số cũ: ${currentWaterReading!['oldReading']}", style: TextStyle(fontSize: 20.sp,fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Image.network(currentWaterReading!['oldImageUrl'], height: 200),
              SizedBox(height: 30.h),
              Text("Chỉ số mới: ${currentWaterReading!['newReading']}", style: TextStyle(fontSize: 20.sp,fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Image.network(currentWaterReading!['newImageUrl'], height: 200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterHistoryTab() {
    if (waterHistory.isEmpty) {
      return Center(child: Text("Chưa có lịch sử chỉ số nước"));
    }

    return ListView.separated(
      itemCount: waterHistory.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final data = waterHistory[index];
        final month = data['month'] ?? '';
        final old = data['oldReading'];
        final newR = data['newReading'];
        final oldImg = data['oldImageUrl'];
        final newImg = data['newImageUrl'];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kỳ: $month", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text("Chỉ số cũ: $old"),
                          SizedBox(height: 4.h),
                          Image.network(oldImg, height: 100),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        children: [
                          Text("Chỉ số mới: $newR"),
                          SizedBox(height: 4.h),
                          Image.network(newImg, height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉ số nước',
          style: TextStyle(
          color: Colors.white,
          fontFamily: "Oswald",
          fontWeight: FontWeight.bold,
          fontSize: 25.sp,
        ),),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
          child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 16.w, left: 16.w, top: 20.h, bottom: 5.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Chỉ số hiện tại", 0, _selectedTab == 0),
              SizedBox(width: 12.w),
              _buildTabButton("Lịch sử các tháng", 1, _selectedTab == 1),
            ],
          ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: _selectedTab == 0
                  ? _buildCurrentWaterTab()
                  : _buildWaterHistoryTab(),
            ),
          ),
        ],
      )),
    );
  }
}
