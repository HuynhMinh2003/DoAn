import 'package:do_an/src/models/apartment.dart';
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

      // Duyệt qua từng tài liệu và phân loại dữ liệu
      for (var doc in querySnapshot.docs) {
        final apartment = Apartment.fromFirestore(doc);
        if (apartment.isRent) {
          rented++;
        } else if (apartment.isSale) {
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
    ScreenUtil.init(context, designSize: const Size(390, 844)); // Configure ScreenUtil
    final total = rentedCount + soldCount + vacantCount;

    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phần chú thích nằm bên trái
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chú thích:',
                            style: TextStyle(
                              fontSize: 4.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          LegendItem(color: Colors.blue, label: 'Thuê'),
                          SizedBox(height: 8.h),
                          LegendItem(color: Colors.green, label: 'Mua'),
                          SizedBox(height: 8.h),
                          LegendItem(color: Colors.grey, label: 'Trống'),
                        ],
                      ),
                      SizedBox(width: 16.w), // Khoảng cách giữa chú thích và biểu đồ
                      // Phần biểu đồ nằm bên phải
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: Colors.blue,
                                value: rentedCount.toDouble(),
                                title:
                                'Thuê\n${((rentedCount / total) * 100).toStringAsFixed(1)}%',
                                radius: 90.r,
                                titleStyle: TextStyle(
                                  fontSize: 4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.green,
                                value: soldCount.toDouble(),
                                title:
                                'Mua\n${((soldCount / total) * 100).toStringAsFixed(1)}%',
                                radius: 90.r,
                                titleStyle: TextStyle(
                                  fontSize: 4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.grey,
                                value: vacantCount.toDouble(),
                                title:
                                'Trống\n${((vacantCount / total) * 100).toStringAsFixed(1)}%',
                                radius: 90.r,
                                titleStyle: TextStyle(
                                  fontSize: 4.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 0,
                            centerSpaceRadius: 50.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Biểu đồ tròn thể hiện tỷ lệ căn hộ đã thuê, đã mua và còn trống',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 4.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
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
          label,
          style: TextStyle(
            fontSize: 4.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}