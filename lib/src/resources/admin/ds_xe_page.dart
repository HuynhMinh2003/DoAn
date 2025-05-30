import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/company_info.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:do_an/src/resources/admin/ds_congty_mobile_page.dart' if (dart.library.html) 'package:do_an/src/resources/admin/ds_congty_web_page.dart';

class CompanyListPage extends StatefulWidget {
  const CompanyListPage({super.key});

  @override
  State<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  final AuthBloc _authBloc = AuthBloc();

  List<CompanyInfo> _companyList = [];
  List<CompanyInfo> _allCompanyList = []; // Lưu danh sách đầy đủ của nhân viên

  String? _selectedCompanyStatus;
  List<String> _companyStatusItems = ["Tất cả", "Đang hợp tác", "Đã thôi"]; // Các giá trị trạng thái nhân viên

  String _searchQueryName = ""; // Biến lưu trữ giá trị tìm kiếm
  String _searchQueryType = ""; // Biến lưu trữ giá trị tìm kiếm
  int itemsPerPage = 10;
  int currentPage = 1;
  int totalPages = 0;
  List<CompanyInfo> paginatedCompanies = [];
  List<int> pageNumbers = [];

  void updatePaginatedCompanies() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > _companyList.length) {
        endIndex = _companyList.length;
      }

      paginatedCompanies = _companyList.sublist(startIndex, endIndex);
      totalPages = (_companyList.length / itemsPerPage).ceil();
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
    _fetchCompany();
  }

  void _fetchCompany() async {
    final snapshot = await FirebaseFirestore.instance.collection('companies').get();
    final companyList = snapshot.docs.map((doc) => CompanyInfo.fromFirestore(doc)).toList();

    if (!mounted) return; // Thêm dòng này để tránh lỗi setState sau dispose

    setState(() {
      _allCompanyList = companyList;
      _companyList = companyList;
    });
  }


  void _filterCompany() {
    List<CompanyInfo> filteredList = _allCompanyList;

    // Filter by name
    if (_searchQueryName.isNotEmpty) {
      filteredList = filteredList
          .where((company) => company.name.toLowerCase().contains(_searchQueryName.toLowerCase()))
          .toList();
    }

    // Filter by type
    if (_searchQueryType.isNotEmpty) {
      filteredList = filteredList
          .where((company) => company.type.toLowerCase().contains(_searchQueryType.toLowerCase()))
          .toList();
    }

    if (_selectedCompanyStatus != null && _selectedCompanyStatus != "Tất cả") {
      final isWorking = _selectedCompanyStatus == "Đang hợp tác";
      filteredList = filteredList.where((company) => company.isExit != isWorking).toList();
    }

    if(mounted){
      setState(() {
        _companyList = filteredList;
        updatePaginatedCompanies();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
                child: ConstrainedBox(constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(flex:1,child:  Text(
                              'Danh sách công ty',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),),
                            Flexible(flex:1,child: ElevatedButton(
                              onPressed: () => exportCompaniesToExcel(_companyList),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload),
                                  SizedBox(width: 5.w,),
                                  Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),)
                                ],
                              ),
                            ),)
                          ],),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: buildFilterDropdown(
                                label: "Lọc theo trạng thái công ty",
                                items: _companyStatusItems,
                                selectedValue: _selectedCompanyStatus,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompanyStatus = value;
                                    _filterCompany();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 20.w,),

                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Tìm kiếm theo tên",
                                  hintText: "Nhập tên công ty",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQueryName = value;
                                    _filterCompany(); // Lọc danh sách khi nhập
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 20.w,),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Tìm kiếm theo loại dịch vụ",
                                  hintText: "Nhập loại dịch vụ",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQueryType = value;
                                    _filterCompany(); // Lọc danh sách khi nhập
                                  });
                                },
                              ),
                            ),],),
                        SizedBox(height: 20.h,),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 360.h ,
                          child:  LayoutBuilder(
                            builder: (context,constraints){
                              return Column(
                                children: [

                                  if(_companyList.isEmpty)
                                    Expanded(child: Center(child: Text("Không có công ty nào"),))
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
                                              DataColumn(label: Text("Tên công ty", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Email", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Loại hình", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text('Địa chỉ', style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text('Số điện thoại', style: TextStyle(fontSize: 4.sp))),
                                            ],
                                            rows: _companyList.map((company) {
                                              return DataRow(cells: [
                                                DataCell(Text(company.name, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.email, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.type, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.address, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.phone, style: TextStyle(fontSize: 4.sp))),
                                              ]);
                                            }).toList(),
                                            rowsPerPage: itemsPerPage,
                                            availableRowsPerPage: [5, 10, 20, 50], // Các tùy chọn số hàng mỗi trang
                                            onRowsPerPageChanged: (value) {
                                              setState(() {
                                                itemsPerPage = value ?? 10; // Cập nhật số hàng mỗi trang
                                                currentPage = 1; // Reset về trang đầu
                                                updatePaginatedCompanies();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              );
                            },
                          ),

                        )
                      ],
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
      padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 0.h),
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
                  border: Border.all(color: Colors.grey),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 147.w,
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
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500)),
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







