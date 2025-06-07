import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminWebPage extends StatefulWidget {
  const AdminWebPage({super.key});

  @override
  State<AdminWebPage> createState() => _AdminWebPageState();
}

class _AdminWebPageState extends State<AdminWebPage> {
  int rentedCount = 0;
  int soldCount = 0;
  int vacantCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('apartments').get();

      int rented = 0;
      int sold = 0;
      int vacant = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['isRent'] == true) {
          rented++;
        } else if (data['isSale'] == true) {
          sold++;
        } else {
          vacant++;
        }
      }

      setState(() {
        rentedCount = rented;
        soldCount = sold;
        vacantCount = vacant;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = rentedCount + soldCount + vacantCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 13.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w),
                child: Text(
                  'Xin chào quản lý 👋',
                  style: TextStyle(
                    fontFamily: "Oswald",
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              // Main Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Cards
                        Row(
                          children: [
                            Expanded(
                              child: StatisticCard(
                                icon: Icons.home_filled,
                                label: "Đã thuê",
                                value: rentedCount,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: StatisticCard(
                                icon: Icons.check_box,
                                label: "Đã bán",
                                value: soldCount,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: StatisticCard(
                                icon: Icons.check_box,
                                label: "Đang trống",
                                value: vacantCount,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Pie Chart Section
                        Container(
                          padding: EdgeInsets.all(22.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Pie Chart
                              Expanded(
                                child: SizedBox(
                                  height: 200.h,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          color: Colors.blue,
                                          value: rentedCount.toDouble(),
                                          title:
                                          '${((rentedCount / total) * 100).toStringAsFixed(1)}%',
                                          radius: 60.r,
                                          titleStyle: TextStyle(
                                            fontSize: 3.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          color: Colors.green,
                                          value: soldCount.toDouble(),
                                          title:
                                          '${((soldCount / total) * 100).toStringAsFixed(1)}%',
                                          radius: 60.r,
                                          titleStyle: TextStyle(
                                            fontSize: 3.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          color: Colors.grey.shade400,
                                          value: vacantCount.toDouble(),
                                          title:
                                          '${((vacantCount / total) * 100).toStringAsFixed(1)}%',
                                          radius: 60.r,
                                          titleStyle: TextStyle(
                                            fontSize: 3.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 40.r,
                                    ),
                                  ),
                                ),
                              ),
                              // Legend
                              Padding(
                                padding: EdgeInsets.only(left: 16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LegendItem(
                                      color: Colors.blue,
                                      label: "Thuê",
                                      percentage:
                                      (rentedCount / total * 100).toStringAsFixed(1),
                                    ),
                                    LegendItem(
                                      color: Colors.green,
                                      label: "Mua",
                                      percentage:
                                      (soldCount / total * 100).toStringAsFixed(1),
                                    ),
                                    LegendItem(
                                      color: Colors.grey.shade400,
                                      label: "Trống",
                                      percentage:
                                      (vacantCount / total * 100).toStringAsFixed(1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w), // Space between Expanded sections
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Thông báo chung",
                                style: TextStyle(
                                  fontSize: 6.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "- Họp cư dân tháng 4",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                "- Bảo trì thang máy",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                "- Thu thêm phí mới ",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30.h,),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Danh sách sự cố",
                                style: TextStyle(
                                  fontSize: 6.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "- Tòa A, căn hộ 1-01: Hỏng cửa ",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "- Tòa B, căn hộ 1-03: Mất nước ",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "- Tòa B, căn hộ 1-04: Mất nước ",
                                style: TextStyle(fontSize: 4.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ),
                ],
              ),
            ],
          ),
        )
      ),
    );
  }
}

class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const StatisticCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 10.sp, color: color), // Kích thước icon giảm
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '$label: $percentage%',
          style: TextStyle(
            fontSize: 4.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}