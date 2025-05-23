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
import 'package:shimmer/shimmer.dart';
import 'ds_nhanvien_mobile_page.dart' if (dart.library.html) 'ds_nhanvien_web_page.dart';

class RateStaffPage extends StatefulWidget {
  const RateStaffPage({super.key});

  @override
  State<RateStaffPage> createState() => _RateStaffPageState();
}

class _RateStaffPageState extends State<RateStaffPage> {
  String? _selectedPosition;
  String? _selectedStatus;

  String? _selectedEmploymentStatus;
  List<String> _employmentStatusItems = ["Tất cả", "Đang làm", "Đã nghỉ"]; // Các giá trị trạng thái nhân viên

  List<String> _positionItems = [];
  List<String> _statusItems = ["Tất cả", "Đang rảnh", "Đang bận"];

  List<Staff> _staffList = [];
  List<Staff> _allStaffList = [];

  String _searchQuery = "";

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 0;
  List<Staff> paginatedStaffs = [];
  List<int> pageNumbers = [];

  bool _isLoading = true; // trạng thái loading giả định

  void updatePaginatedStaffs() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > _staffList.length) {
        endIndex = _staffList.length;
      }

      paginatedStaffs = _staffList.sublist(startIndex, endIndex);
      totalPages = (_staffList.length / itemsPerPage).ceil();
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
    _fetchPositions();
    _fetchStaff();
    currentPage = 1;
    updatePaginatedStaffs();
  }

  void _fetchPositions() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("positions").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) { // Kiểm tra widget có còn tồn tại
        setState(() {
          _positionItems = ["Tất cả"];
          _positionItems.addAll(data.values.map((e) => e.toString()));
        });
      }
    }
  }

  void _fetchStaff() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('staffs').get();
      final staffList = snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();

      if (mounted) { // Kiểm tra widget có còn tồn tại
        setState(() {
          _allStaffList = staffList;
          _staffList = staffList;
          currentPage = 1;
          updatePaginatedStaffs();
          _isLoading = false; // THÊM DÒNG NÀY
        });
      }
    } catch (e) {
      if (mounted) { // Chỉ hiển thị lỗi nếu widget còn tồn tại
        print("Lỗi khi lấy danh sách nhân viên: $e");
      }
    }
  }

  void _filterStaff() {
    List<Staff> filteredList = _allStaffList;

    if (_selectedPosition != null && _selectedPosition != "Tất cả") {
      filteredList = filteredList.where((staff) => staff.position == _selectedPosition).toList();
    }

    if (_selectedStatus != null && _selectedStatus != "Tất cả") {
      final isFree = _selectedStatus == "Đang rảnh";
      filteredList = filteredList.where((staff) => staff.isFree == isFree).toList();
    }

    if (_selectedEmploymentStatus != null && _selectedEmploymentStatus != "Tất cả") {
      final isWorking = _selectedEmploymentStatus == "Đang làm";
      filteredList = filteredList.where((staff) => staff.isExit != isWorking).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((staff) => staff.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (mounted) { // Kiểm tra widget còn trong cây
      setState(() {
        _staffList = filteredList;
        updatePaginatedStaffs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/images/two_circle.png',
                  width: 160,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 170.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Đánh giá nhân viên',
                        style: TextStyle(
                          fontFamily: "Oswald",
                          fontWeight: FontWeight.w700,
                          fontSize: 40.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Tìm kiếm theo tên",
                        hintText: "Nhập tên nhân viên",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterStaff();
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    buildFilterDropdown(
                      label: "Lọc theo chức vụ",
                      items: _positionItems,
                      selectedValue: _selectedPosition,
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                          _filterStaff();
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: _isLoading
                          ? _buildShimmerList()
                          : _staffList.isEmpty
                          ? Center(
                        child: Text(
                          "Không có nhân viên nào",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black54,
                          ),
                        ),
                      )
                          : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: paginatedStaffs.length,
                              itemBuilder: (context, index) {
                                final staff = paginatedStaffs[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16.r),
                                  ),
                                  elevation: 3,
                                  margin: EdgeInsets.symmetric(
                                      vertical: 8.h),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                      Colors.blueAccent,
                                      child: Text(
                                        staff.fullName.isNotEmpty
                                            ? staff.fullName[0]
                                            .toUpperCase()
                                            : "?",
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      staff.fullName,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                        "Chức vụ: ${staff.position}"),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      // Xử lý khi click
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_staffList.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: pageNumbers.map((page) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.w),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        page == currentPage
                                            ? Colors.blue
                                            : Colors.grey[300],
                                        foregroundColor:
                                        page == currentPage
                                            ? Colors.white
                                            : Colors.black,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                              10.r),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          currentPage = page;
                                          updatePaginatedStaffs();
                                        });
                                      },
                                      child: Text("$page"),
                                    ),
                                  );
                                }).toList(),
                              ),
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
      ),
    );
  }


  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 10.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.white, radius: 24.r),
              title: Container(
                width: double.infinity,
                height: 14.h,
                color: Colors.white,
              ),
              subtitle: Container(
                margin: EdgeInsets.only(top: 8.h),
                width: 100.w,
                height: 12.h,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
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
                style: TextStyle(fontSize: 15.sp ),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(), // Ép kiểu thành String cho cả String và int
                    style: TextStyle(fontSize: 15.sp ),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 40.w ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 331.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 40.w ),
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







