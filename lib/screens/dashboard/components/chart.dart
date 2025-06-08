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
  int withContract = 0;
  int withoutContract = 0;
  bool isLoading = true;
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('apartments').get();

      int tempWithContract = 0;
      int tempWithoutContract = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final currentContractId = data['currentContractId'];

        if (currentContractId != null &&
            currentContractId.toString().isNotEmpty) {
          tempWithContract++;
        } else {
          tempWithoutContract++;
        }
      }

      if (mounted) {
        setState(() {
          withContract = tempWithContract;
          withoutContract = tempWithoutContract;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (index) {
      final isTouched = index == touchedIndex;
      final double radius = isTouched ? 30.0 : 25.0;
      final double fontSize = isTouched ? 16.0 : 0.0;
      final contractLabel = index == 0 ? "Có hợp đồng" : "Chưa có hợp đồng";
      final value = index == 0 ? withContract : withoutContract;

      return PieChartSectionData(
        color: index == 0 ? primaryColor : const Color(0xFFFFCF26),
        value: value.toDouble(),
        title: isTouched ? "$contractLabel\n$value căn" : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SizedBox(
      height: 220,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: showingSections(),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: defaultPadding),
                Text(
                  "${withContract + withoutContract}",
                  style:
                  Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 0.5,
                  ),
                ),
                const Text("Tổng căn hộ"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
