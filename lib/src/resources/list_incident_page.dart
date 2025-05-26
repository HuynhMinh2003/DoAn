import 'package:do_an/constants.dart';
import 'package:do_an/custom_paginated_table.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/models/staffs.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/incident.dart';
import 'ds_nhanvien_mobile_page.dart' if (dart.library.html) 'ds_nhanvien_web_page.dart';

class ListIncidentPage extends StatefulWidget {
  const ListIncidentPage({super.key});

  @override
  State<ListIncidentPage> createState() => _ListIncidentPageState();
}

class _ListIncidentPageState extends State<ListIncidentPage> {
  String? _selectedPriority;
  String? _selectedStatus;

  String? _selectedEmploymentStatus;
  List<String> _priorityItems = ["Tất cả", "Cao", "Trung bình", "Thấp"]; // Các giá trị trạng thái nhân viên

  // List<String> _positionItems = [];
  List<String> _statusItems = ["Tất cả", "Đang chờ xử lý", "Đang xử lý", "Đã xử lý"];

  List<Incident> _incidentList = [];
  List<Incident> _alIncidentList = [];
  List<Staff> _allStaffs = [];

  String _searchQuery = "";

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 0;
  List<Incident> paginatedIncidents = [];
  List<int> pageNumbers = [];

  bool _isEditDialogShowing = false;
  bool _isDeleteDialogShowing = false;
  bool _isViewDialogShowing = false;

  final AuthBloc _authBloc = AuthBloc();

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

  void updatePaginatedIncidents() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > _incidentList.length) {
        endIndex = _incidentList.length;
      }

      paginatedIncidents = _incidentList.sublist(startIndex, endIndex);
      totalPages = (_incidentList.length / itemsPerPage).ceil();
      updatePageNumbers();
    });
  }

  void updatePageNumbers() {
    int startPage = currentPage - 1;
    if (startPage < 0) startPage = 0;

    pageNumbers = List.generate(3, (index) {
      int page = startPage + index;
      if (page < totalPages) {
        return page + 1;
      }
      return -1;
    }).where((page) => page != -1).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadStaffs();
    _fetchStatus();
    _fetchPriority();
    _fetchIncident();
    _alIncidentList = _incidentList;
    currentPage = 1;
    updatePaginatedIncidents();
  }

  void _fetchStatus() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("status").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) { // Kiểm tra widget có còn tồn tại
        setState(() {
          _statusItems = ["Tất cả"];
          _statusItems.addAll(data.values.map((e) => e.toString()));
        });
      }
    }
  }

  void _fetchPriority() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("priority").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) { // Kiểm tra widget có còn tồn tại
        setState(() {
          _priorityItems = ["Tất cả"];
          _priorityItems.addAll(data.values.map((e) => e.toString()));
        });
      }
    }
  }

  void _fetchIncident() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('incidents').get();
      final incidentList = snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();

      if (mounted) { // Kiểm tra widget có còn tồn tại
        setState(() {
          _alIncidentList = incidentList;
          _incidentList = incidentList;
          currentPage = 1;
          updatePaginatedIncidents();
        });
      }
    } catch (e) {
      if (mounted) { // Chỉ hiển thị lỗi nếu widget còn tồn tại
        print("Lỗi khi lấy danh sách nhân viên: $e");
      }
    }
  }

  void _filterStaff() {
    List<Incident> filteredList = _alIncidentList;

    if (_selectedPriority != null && _selectedPriority != "Tất cả") {
      filteredList = filteredList.where((incident) => incident.priority == _selectedPriority).toList();
    }

    if (_selectedStatus != null && _selectedStatus != "Tất cả") {
      filteredList = filteredList.where((incident) => incident.status == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((incident) => incident.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (mounted) { // Kiểm tra widget còn trong cây
      setState(() {
        _incidentList = filteredList;
        updatePaginatedIncidents();
      });
    }
  }

  Future<void> showViewIncidentDialog(BuildContext context, Incident incident, VoidCallback onRefresh) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Thông tin sự cố",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 7.sp,
              color: Colors.blueAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: incident.imageUrl!.isNotEmpty
                          ? Image.network(
                        incident.imageUrl!,
                        width: 300,
                        height: 360,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'assets/default_avatar.png',
                        width: 300,
                        height: 360,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: buildInfoRow("Tên căn hộ:", incident.apartmentAddress)),
                          SizedBox(width: 10.w),
                          Text("/", style: TextStyle(fontSize: 4.sp)),
                          SizedBox(width: 10.w),
                          Expanded(child: buildInfoRow("", incident.building)),
                        ],
                      ),
                      buildInfoRow("Người báo:", incident.reporterName),
                      buildInfoRow("Tiêu đề:", incident.title),
                      buildInfoRow("Mô tả:", incident.description),
                      buildInfoRow("Nhân viên xử lí:", incident.assignedStaffName ?? "Chưa cập nhật"),
                      Row(
                        children: [
                          Expanded(
                            child: buildInfoRow(
                              "Gửi vào:",
                              incident.createdAt != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt!.toDate())
                                  : "Chưa cập nhật",
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text("/", style: TextStyle(fontSize: 4.sp)),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: buildInfoRow(
                              "Đã xử lí vào:",
                              incident.handledAt != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(incident.handledAt!.toDate())
                                  : "Chưa cập nhật",
                            ),
                          ),
                        ],
                      ),
                      buildInfoRow("Ghi chú của quản lí:", incident.managerNote ?? "Không có"),
                      buildInfoRow("Trạng thái:", incident.status),
                    ],
                  ),
                )
              ],
            ),
          ),
          actions: [
            if (incident.status == "Đang chờ xử lý") ...[
              TextButton(
                onPressed: () => _openAssignDialog(incident),
                child: Text("Chọn nhân viên xử lí", style: TextStyle(fontSize: 4.sp)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
              ),
            ] else if (incident.status == "Đang xử lý") ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
              ),
            ] else if (incident.status == "Đã xử lý") ...[
              TextButton(
                onPressed: () => _showHandledHistoryDialog(context, incident.id),
                child: Text("Xem lịch sử xử lý", style: TextStyle(fontSize: 4.sp)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
              ),
            ],
          ],

        );
      },
    );
  }

  Future<void> _openAssignDialog(Incident incident) async{
    showDialog(
      context: context,
      builder: (_) {
        final _noteController = TextEditingController();
        Staff? selectedStaff = null;
        String? selectedPriority = incident.priority ?? 'Trung bình';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Giao sự cố cho nhân viên'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration:
                      const InputDecoration(labelText: 'Mức độ ưu tiên'),
                      items: ['Cao', 'Trung bình', 'Thấp']
                          .map((level) => DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Staff>(
                      value: selectedStaff,
                      decoration:
                      const InputDecoration(labelText: 'Chọn nhân viên'),
                      items: _allStaffs.map((staff) {
                        return DropdownMenuItem<Staff>(
                          value: staff,
                          enabled: staff.isFree,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: staff.isFree ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(staff.fullName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (staff) {
                        if (staff?.isFree == true) {
                          setState(() {
                            selectedStaff = staff;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                          labelText: 'Ghi chú cho nhân viên (nếu có)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
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
                  child: const Text('Xác nhận giao'),
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
      'status': 'Đang xử lý',
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
    _loadStaffs();
  }

  Future<void> _showHandledHistoryDialog(BuildContext context, String incidentId) async {
    final historyRef = FirebaseFirestore.instance
        .collection("incidents")
        .doc(incidentId)
        .collection("handledHistory");

    final historySnapshot = await historyRef.orderBy("responseTime", descending: true).get();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Center(child: Text(
            "Lịch sử xử lý",
            style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold, color: Colors.blue),
          ),),
          content: historySnapshot.docs.isEmpty
              ? Text("Không có dữ liệu lịch sử xử lý.")
              : SizedBox(
            width: 100.w,
            child: SingleChildScrollView(
              child: Column(
                children: historySnapshot.docs.map((doc) {
                  final data = doc.data();
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    color: secondaryColor,
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: data['proofImageUrl'].isNotEmpty
                                    ? Image.network(
                                  data['proofImageUrl'],
                                  width: 100,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                                    : Image.asset(
                                  'assets/default_avatar.png',
                                  width: 100,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(flex:6,child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Nhân viên: ${data['staffName'] ?? 'N/A'}", style: TextStyle(fontSize:3.sp)),
                              SizedBox(height: 10.h),
                              Text("Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(data['responseTime'].toDate())}", style: TextStyle(fontSize:3.sp)),
                              SizedBox(height: 10.h),
                              Text("Ghi chú: ${data['note'] ?? 'Không có'}", style: TextStyle(fontSize:3.sp)),
                              SizedBox(height: 10.h),
                              Text("Trạng thái: ${data['accepted'] == true ? 'Đã xử lí' : 'Từ chối'}",
                                  style: TextStyle(color: data['accepted'] == true ? Colors.green : Colors.red, fontSize: 3.sp)),
                              SizedBox(height: 10.h),
                              if (data['rejectionReason'] != null) ...[
                                SizedBox(height: 10.h),
                                Text("Lý do từ chối: ${data['rejectionReason']}", style: TextStyle(fontSize:3.sp)),
                              ],
                            ],
                          ))
                        ],),
                      ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
            ),
          ],
        );
      },
    );
  }
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Đang chờ xử lý':
        return Icons.hourglass_empty;
      case 'Đang xử lý':
        return Icons.settings;
      case 'Đã xử lý':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Đang chờ xử lý':
        return Colors.orange;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Đã xử lý':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }


  /// Hàm hỗ trợ để hiển thị thông tin dưới dạng hàng
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.sp),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 4.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
                child: ConstrainedBox(constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                  child:  Padding(
                    padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              flex:3,child: Text(
                              'Danh sách sự cố',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),),
                            Flexible(flex:2, child: TextField(
                              decoration: InputDecoration(
                                labelText: "Tìm kiếm theo tên",
                                hintText: "Nhập tên sự cố",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _filterStaff(); // Lọc danh sách khi nhập
                                });
                              },
                            ),),
                            SizedBox(width:5.w),

                          ],
                        ),
                        SizedBox(height: 10.h,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: buildFilterDropdown(
                                label: "Lọc theo mức độ sự cố",
                                items: _priorityItems,
                                selectedValue: _selectedPriority,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value;
                                    _filterStaff();
                                  });
                                },
                              ),
                            ),

                            SizedBox(width: 20.w), // Khoảng cách giữa tiêu đề và tìm kiếm

                            Expanded(child: buildFilterDropdown(
                              label: "Lọc theo trạng thái xử lý",
                              items: _statusItems,
                              selectedValue: _selectedStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                  _filterStaff();
                                });
                              },
                            ),)
                            ]),
                        SizedBox(height: 20.h),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 150.h,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: [
                                  if (_incidentList.isEmpty)
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          "Không có sự cố nào",
                                          style: TextStyle(fontSize: 4.sp, color: Colors.black54),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth, // Đặt chiều rộng tối thiểu bằng chiều rộng cha
                                            maxWidth: constraints.maxWidth, // Đặt chiều rộng tối đa bằng chiều rộng cha
                                          ),
                                          child: CustomPaginatedTable(
                                            columns: [
                                              DataColumn(label: Text("Tòa", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Địa chỉ", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Người báo", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Tên sự cố", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Thời gian báo", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Mức độ", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Trạng thái", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Chi tiết", style: TextStyle(fontSize: 4.sp))),
                                            ],
                                            rows: paginatedIncidents.map((incident) {
                                              return DataRow(cells: [
                                                DataCell(Text(
                                                  incident.building ?? 'Chưa xác định',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Text(
                                                  incident.apartmentAddress ?? 'Chưa xác định',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Text(
                                                  incident.reporterName ?? 'Chưa xác định',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Text(
                                                  incident.title ?? 'Chưa xác định',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Text(
                                                  incident.createdAt != null
                                                      ? DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt!.toDate())
                                                      : 'Chưa xác định',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Text(
                                                  incident.priority ?? 'Không rõ',
                                                  style: TextStyle(fontSize: 4.sp),
                                                )),
                                                DataCell(Row(
                                                  children: [
                                                    Icon(
                                                      _getStatusIcon(incident.status),
                                                      color: _getStatusColor(incident.status),
                                                      size: 4.5.sp,
                                                    ),
                                                    SizedBox(width: 2.w),
                                                    Text(
                                                      incident.status ?? 'Không có mô tả',
                                                      style: TextStyle(fontSize: 4.sp),
                                                    ),
                                                  ],
                                                )),

                                                DataCell(IconButton(
                                                  icon: Icon(Icons.info_outline, color: Colors.white),
                                                  onPressed: () async {
                                                    if (_isViewDialogShowing) return;
                                                    _isViewDialogShowing = true;
                                                    try {
                                                      await showViewIncidentDialog(context, incident, _fetchIncident);
                                                    } finally {
                                                      _isViewDialogShowing = false;
                                                    }
                                                  },
                                                )),
                                              ]);
                                            }).toList(),
                                            rowsPerPage: itemsPerPage,
                                            availableRowsPerPage: [5, 10, 20, 50], // Các tùy chọn số hàng mỗi trang
                                            onRowsPerPageChanged: (value) {
                                              setState(() {
                                                itemsPerPage = value ?? 10; // Cập nhật số hàng mỗi trang
                                                currentPage = 1; // Reset về trang đầu
                                                updatePaginatedIncidents();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        )                  ],
                    ),
                  ),)
            ),
          ],
        ),
      ),
    );
  }


// Hàm lọc nhân viên theo chức vụ
  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(fontSize: 4.sp ),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(), // Ép kiểu thành String cho cả String và int
                    style: TextStyle(fontSize: 4.sp ),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 101.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDropdownField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final bool isEditing;
  final double fontSize;

  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.controller,
    required this.options,
    required this.isEditing,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? currentValue = options.contains(controller.text) ? controller.text : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: Colors.grey)),
        SizedBox(height: 2.h),
        DropdownButtonFormField2<String>(
          value: currentValue,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 1.w),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          items: options
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: fontSize)),
          ))
              .toList(),
          onChanged: isEditing ? (value) => controller.text = value! : null,
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
}







