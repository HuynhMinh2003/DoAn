import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class Chart extends StatefulWidget {
  const Chart({Key? key}) : super(key: key);

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  int rented = 0;
  int sold = 0;
  int available = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      // Truy cập collection `apartments` từ Firestore
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('apartments').get();

      int tempRented = 0;
      int tempSold = 0;
      int tempAvailable = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool isRent = data['isRent'] ?? false;
        bool isSale = data['isSale'] ?? false;

        if (isRent) {
          tempRented++;
        } else if (isSale) {
          tempSold++;
        } else {
          tempAvailable++;
        }
      }

      setState(() {
        rented = tempRented;
        sold = tempSold;
        available = tempAvailable;
        isLoading = false; // Kết thúc quá trình tải dữ liệu
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false; // Kết thúc quá trình tải dữ liệu kể cả khi lỗi
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator()) // Hiển thị khi đang tải dữ liệu
        : SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: primaryColor,
                  value: rented.toDouble(),
                  showTitle: false,
                  radius: 25,
                ),
                PieChartSectionData(
                  color: const Color(0xFF26E5FF),
                  value: sold.toDouble(),
                  showTitle: false,
                  radius: 22,
                ),
                PieChartSectionData(
                  color: const Color(0xFFFFCF26),
                  value: available.toDouble(),
                  showTitle: false,
                  radius: 19,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: defaultPadding),
                Text(
                  "${rented + sold + available}",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 0.5,
                  ),
                ),
                const Text("Total Apartments")
              ],
            ),
          ),
        ],
      ),
    );
  }
}