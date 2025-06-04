import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/incident.dart';
import 'package:do_an/src/models/staffs.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ManagerIncidentPage extends StatefulWidget {
  const ManagerIncidentPage({super.key});

  @override
  State<ManagerIncidentPage> createState() => _ManagerIncidentPageState();
}

class _ManagerIncidentPageState extends State<ManagerIncidentPage> {
  List<Incident> _pendingIncidents = [];
  List<Staff> _allStaffs = [];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _loadStaffs();
  }

  Future<void> _loadIncidents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'Đang chờ xử lí')
        .get();

    setState(() {
      _pendingIncidents =
          snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
    });
  }

  Future<void> _loadStaffs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('staffs')
        .where('role', isEqualTo: 2) // Lọc đúng role
        .get();

    setState(() {
      _allStaffs =
          snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();
    });
  }

  Future<void> _openAssignDialog(Incident incident) async{
    showDialog(
      context: context,
      builder: (_) {
        final _noteController = TextEditingController();
        Staff? selectedStaff = null;
        String? selectedPriority = null;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Giao sự cố cho nhân viên', style: TextStyle(fontSize: 5.sp),),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                buildFilterDropdown2<String>(
                hintText: 'Chọn mức độ xử lý',
                  items: ['Cao', 'Trung bình', 'Thấp'],
                  selectedValue: selectedPriority,
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value;
                    });
                  },
                  itemBuilder: (level) => Text(level, style: const TextStyle(fontSize: 14)),
                ),

                  SizedBox(height: 10.h),
                  buildFilterDropdown2<Staff>(
                    hintText: 'Chọn nhân viên',
                    items: _allStaffs,
                    selectedValue: selectedStaff,
                    isEnabled: (staff) => staff.isFree,
                    onChanged: (staff) {
                      if (staff?.isFree == true) {
                        setState(() {
                          selectedStaff = staff;
                        });
                      }
                    },
                    itemBuilder: (staff) => Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: staff.isFree ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(staff.fullName),
                      ],
                    ),
                  ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                          labelText: 'Ghi chú cho nhân viên', labelStyle: TextStyle(fontSize: 4.sp)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(fontSize: 4.sp)),
                ),
                ElevatedButton(
                  onPressed: selectedStaff == null
                      ? null
                      : () async {
                    Navigator.pop(context);
                    await _assignToStaff(
                      incident,
                      _noteController.text.trim(),
                      selectedStaff!,
                      selectedPriority ?? 'Trung bình',
                    );
                  },
                  child: Text('Xác nhận giao', style: TextStyle(fontSize: 4.sp)),
                ),
              ],
            );
          },
        );
      },
    );

  }

  Future<void> _assignToStaff(
      Incident incident,
      String managerNote,
      Staff staff,
      String priority,
      ) async {
    final batch = FirebaseFirestore.instance.batch();

    final incidentRef =
    FirebaseFirestore.instance.collection('incidents').doc(incident.id);
    batch.update(incidentRef, {
      'assignedStaffId': staff.uid,
      'assignedStaffName': staff.fullName,
      'status': 'Đang xử lí',
      'priority': priority,
      'managerNote': managerNote,
    });

    final staffRef =
    FirebaseFirestore.instance.collection('staffs').doc(staff.uid);
    batch.update(staffRef, {'isFree': false});

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã giao cho ${staff.fullName}')),
    );

    _loadIncidents();
    _loadStaffs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Stack(
        children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),child: Padding(padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h, bottom: 10.h),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: Text("Quản lý sự cố cư dân",style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.w700,
                  fontSize: 7.sp,
                ),)),
              ],
            ),
          SizedBox(
            height: MediaQuery.of(context).size.height - 150.h,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _pendingIncidents.isEmpty
                    ? Center(
                  child: Text(
                    'Không có sự cố nào cần xử lý',
                    style: TextStyle(fontSize: 4.sp),
                  ),
                )
                    : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pendingIncidents.length,
                        itemBuilder: (context, index) {
                          final incident = _pendingIncidents[index];
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hình ảnh bên trái
                                  if (incident.imageUrl != null && incident.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        incident.imageUrl!,
                                        width: 60.w,
                                        height: 200.h,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 120.w,
                                      height: 120.h,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.image_not_supported, size: 40),
                                    ),

                                  SizedBox(width: 12.w),

                                  // Nội dung bên phải
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nội dung bên trên
                                        Text(
                                          "Tiêu đề: ${incident.title}",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.sp),
                                        ),
                                        SizedBox(height: 30.h),
                                        Text("Người báo: ${incident.reporterName}", style: TextStyle(fontSize: 4.sp)),
                                        SizedBox(height: 30.h),
                                        Text("Căn hộ: ${incident.apartmentAddress} / ${incident.building}", style: TextStyle(fontSize: 4.sp)),
                                        SizedBox(height: 30.h),
                                        Text("Mô tả: ${incident.description}", style: TextStyle(fontSize: 4.sp)),

                                        // Spacer đẩy nút xuống dưới
                                        Spacer(),

                                        // Nút nằm dưới cùng bên phải
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => _openAssignDialog(incident),
                                              child: Text("Giao xử lí", style: TextStyle(fontSize: 4.sp)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],),)),
      ],))
    );
  }
  Widget buildFilterDropdown2<T>({
    required String hintText,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    required Widget Function(T item) itemBuilder,
    String? labelText,
    bool Function(T)? isEnabled,
    double height = 50,
    double maxHeight = 250,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: DropdownButtonFormField2<T>(
        value: selectedValue == null ? null : selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(
          hintText,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            enabled: isEnabled != null ? isEnabled(item) : true,
            child: itemBuilder(item),
          );
        }).toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: height,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxHeight,
        ),
      ),
    );
  }


}
