import 'package:do_an/src/resources/water_reading_form.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class WaterReadingScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const WaterReadingScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<WaterReadingScreen> createState() => _WaterReadingScreenState();
}

class _WaterReadingScreenState extends State<WaterReadingScreen> {
  late String selectedMonth;
  String? selectedBuilding;
  String? selectedStatus; // null: tất cả, "recorded": đã ghi, "notRecorded": chưa ghi
  List<String> buildingOptions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateFormat('MM-yyyy').format(DateTime(now.year, now.month));
    fetchBuildingOptions();
  }

  List<String> generateMonthList() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return DateFormat('MM-yyyy').format(date);
    });
  }

  Future<void> fetchBuildingOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').get();
    final buildings = snapshot.docs
        .map((doc) => doc.data()['building'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    buildings.sort();
    setState(() {
      buildingOptions = buildings;
    });
  }

  Future<List<Map<String, dynamic>>> fetchValidContracts(String monthKey) async {
    // Chuyển "MM-yyyy" → DateTime
    final parts = monthKey.split('-');
    final selectedMonthStart = DateTime(int.parse(parts[1]), int.parse(parts[0]), 1);
    final selectedMonthEnd = DateTime(selectedMonthStart.year, selectedMonthStart.month + 1, 0);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('contracts')
        .where('isActive', isEqualTo: true)
        .get();

    final validContracts = querySnapshot.docs.where((doc) {
      final data = doc.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();

      final isOverlap = start.isBefore(selectedMonthEnd.add(const Duration(days: 1))) &&
          end.isAfter(selectedMonthStart.subtract(const Duration(days: 1)));

      final matchesBuilding = selectedBuilding == null || data['building'] == selectedBuilding;

      return isOverlap && matchesBuilding;
    }).map((doc) => {
      'contractId': doc.id,
      'data': doc.data(),
    }).toList();

    return validContracts;
  }

  Future<List<Map<String, dynamic>>> fetchContractsWithStatus(List<Map<String, dynamic>> contracts) async {
    List<Map<String, dynamic>> filtered = [];

    for (var contract in contracts) {
      final contractId = contract['contractId'];
      final doc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('waterReadings')
          .doc(selectedMonth) // selectedMonth = MM-yyyy
          .get();

      final hasRecorded = doc.exists;

      if (selectedStatus == null ||
          (selectedStatus == "recorded" && hasRecorded) ||
          (selectedStatus == "notRecorded" && !hasRecorded)) {
        filtered.add({
          ...contract,
          'hasRecorded': hasRecorded,
        });
      }
    }

    filtered.sort((a, b) {
      final dataA = a['data'];
      final dataB = b['data'];

      int floorA = int.tryParse(dataA['building'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int floorB = int.tryParse(dataB['building'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      int aptA = int.tryParse(dataA['apartmentName']) ?? 0;
      int aptB = int.tryParse(dataB['apartmentName']) ?? 0;

      if (floorA != floorB) return floorA.compareTo(floorB);
      return aptA.compareTo(aptB);
    });

    return filtered;
  }

  bool isWaterRecordingPeriod(String selectedMonth) {
    final now = DateTime.now();
    final currentMonth = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    // Nếu đang xem tháng khác với tháng hiện tại → cho phép ghi
    if (selectedMonth != currentMonth) {
      return true;
    }

    // Nếu là tháng hiện tại → chỉ cho ghi từ ngày 25 trở đi
    return now.day >= 10;
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = generateMonthList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ghi chỉ số nước theo tháng',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bộ lọc',style: TextStyle(
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
            ),),
                // Dropdown tháng - cần custom label hơi khác
                buildFilterDropdown<String>(
                  label: 'Chọn tháng',
                  items: monthOptions,
                  selectedValue: selectedMonth,
                  onChanged: (val) => setState(() => selectedMonth = val!),

                  // Tùy chỉnh cách hiển thị label trong item
                  itemLabelBuilder: (item) =>
                  "Tháng ${item?.substring(0, 2)} - ${item?.substring(3)}",
                ),

                SizedBox(height: 10.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: buildFilterDropdown1<String>(
                      label: 'Lọc theo tòa nhà',
                      items: buildingOptions,
                      selectedValue: selectedBuilding,
                      onChanged: (val) => setState(() => selectedBuilding = val),
                    ),),

                    SizedBox(width: 10.w),

                    // Dropdown trạng thái ghi chỉ số - có giá trị null
                    Expanded(child: buildFilterDropdown1<String?>(
                      label: 'Lọc theo trạng thái',
                      items: ['recorded', 'notRecorded'],
                      selectedValue: selectedStatus,
                      onChanged: (val) => setState(() => selectedStatus = val),
                      itemLabelBuilder: (item) {
                        switch (item) {
                          case 'recorded':
                            return 'Đã ghi chỉ số';
                          case 'notRecorded':
                            return 'Chưa ghi chỉ số';
                          default:
                            return item.toString();
                        }
                      },
                    ),),
                  ],
                )
              ],
            ),
          ),
          Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Danh sách',
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (!isWaterRecordingPeriod(selectedMonth))
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "⚠️ Bạn chỉ có thể ghi chỉ số nước từ ngày 25 đến cuối tháng.",
                style: TextStyle(color: Colors.orange, fontSize: 15.sp),
              ),
            )
          else
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchValidContracts(selectedMonth).then(fetchContractsWithStatus),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final contracts = snapshot.data ?? [];

                  if (contracts.isEmpty) {
                    return Center(
                      child: Text(
                        "Không có dữ liệu hợp lệ.",
                        style: TextStyle(fontSize: 15.sp),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: contracts.length,
                    itemBuilder: (context, index) {
                      final contract = contracts[index];
                      final data = contract['data'];
                      final contractId = contract['contractId'];
                      final apartmentName = data['apartmentName'];
                      final building = data['building'];
                      final hasRecorded = contract['hasRecorded'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$building / Căn $apartmentName',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                hasRecorded ? Icons.check_circle : Icons.error_outline,
                                color: hasRecorded ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: SingleChildScrollView(
                                  child: WaterReadingForm(
                                    contractId: contractId,
                                    apartmentName: apartmentName,
                                    building: building,
                                    staffId: widget.staffId,
                                    staffName: widget.staffName,
                                    selectedMonth: selectedMonth,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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

  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T?)? itemLabelBuilder, // <-- Thêm tham số này vào đây
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 50.h,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            items: items.map((item) {
              final labelText = itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : (item?.toString() ?? '');
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelText,
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            value: selectedValue,
            onChanged: onChanged,
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey.shade400),
                color: Colors.white,
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 180.h,
              width: 360.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: Colors.white,
              ),
              elevation: 6,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
            ),
            iconStyleData: IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF00C2B3)),
              iconSize: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFilterDropdown1<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T?)? itemLabelBuilder, // <-- Thêm tham số này vào đây
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 50.h,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
            ),
            items: items.map((item) {
              final labelText = itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : (item?.toString() ?? '');
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelText,
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            value: selectedValue,
            onChanged: onChanged,
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey.shade400),
                color: Colors.white,
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 180.h,
              width: 170.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: Colors.white,
              ),
              elevation: 6,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
            ),
            iconStyleData: IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF00C2B3)),
              iconSize: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
