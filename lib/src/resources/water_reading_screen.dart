import 'dart:io';

import 'package:do_an/src/resources/water_reading_form.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'water_reading_screen.dart'; // import file bạn vừa tạo ở trên

class WaterReadingScreen extends StatefulWidget {
  const WaterReadingScreen({super.key});

  @override
  State<WaterReadingScreen> createState() => _WaterReadingScreenState();
}

class _WaterReadingScreenState extends State<WaterReadingScreen> {
  late String selectedMonth; // e.g., '2025-04'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month)); // ✅ chọn tháng hiện tại
  }

  List<String> generateMonthList() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return DateFormat('yyyy-MM').format(date);
    });
  }

  Future<List<Map<String, dynamic>>> fetchValidContracts(String monthKey) async {
    final selectedMonthStart = DateTime.parse('$monthKey-01');
    final selectedMonthEnd = DateTime(selectedMonthStart.year, selectedMonthStart.month + 1, 0); // cuối tháng

    final snapshot = await FirebaseFirestore.instance.collection('contracts').get();

    final validContracts = snapshot.docs.where((doc) {
      final data = doc.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();

      // So sánh khoảng giao nhau giữa khoảng hợp đồng và khoảng tháng
      final isOverlap =
          start.isBefore(selectedMonthEnd.add(const Duration(days: 1))) &&
              end.isAfter(selectedMonthStart.subtract(const Duration(days: 1)));

      print("Hợp đồng ${doc.id}: $start → $end, tháng: $selectedMonthStart → $selectedMonthEnd, hợp lệ: $isOverlap");

      return isOverlap;
    }).map((doc) => {
      'contractId': doc.id,
      'data': doc.data(),
    }).toList();

    print("Tìm thấy ${validContracts.length} hợp đồng hợp lệ");

    return validContracts;
  }


  @override
  Widget build(BuildContext context) {
    final monthOptions = generateMonthList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ghi chỉ số nước theo tháng"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedMonth,
              items: monthOptions
                  .map((month) => DropdownMenuItem(
                value: month,
                child: Text("Tháng ${month.substring(5)} - ${month.substring(0, 4)}"),
              ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedMonth = val);
                }
              },
              decoration: const InputDecoration(labelText: "Chọn tháng"),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchValidContracts(selectedMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contracts = snapshot.data ?? [];

                if (contracts.isEmpty) {
                  return const Center(child: Text("Không có hợp đồng hợp lệ cho tháng này."));
                }

                return ListView.builder(
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    final data = contract['data'];
                    return WaterReadingForm(
                      contractId: contract['id'], // ✅ sửa key 'contractId' → 'id'
                      apartmentName: data['apartmentName'],
                      building: data['building'],
                      selectedMonth: selectedMonth,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
