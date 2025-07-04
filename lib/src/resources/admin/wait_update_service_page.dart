import 'package:flutter/foundation.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';
import '../../../custom_paginated_table.dart';
import 'package:do_an/src/resources/wait_update_service_mobile_page.dart' if (dart.library.html) 'wait_update_service_web_page.dart';

class WaitUpdateServicePage extends StatefulWidget {
  const WaitUpdateServicePage({super.key});

  @override
  State<WaitUpdateServicePage> createState() => _WaitUpdateServicePageState();
}

class _WaitUpdateServicePageState extends State<WaitUpdateServicePage> {
  String? _selectedServiceType; // ✅ ban đầu đã có giá trị
  String _searchCompanyName = "";
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Tất cả',
    'Đang chờ duyệt',
    'Đã duyệt',
    'Từ chối duyệt',
  ];

  List<String> _serviceTypeOptions = ["Tất cả"];
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _filteredServices = [];

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 0;
  List<Map<String, dynamic>> paginatedServices = [];
  List<int> pageNumbers = [];

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadServicesWithCompanyInfo();
  }

  Future<void> _loadServicesWithCompanyInfo() async {
    try {
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      List<Map<String, dynamic>> allServices = [];

      for (var companyDoc in companiesSnapshot.docs) {
        final companyId = companyDoc.id;
        final companyData = companyDoc.data();

        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('updateService')
            .get();

        print("Công ty ${companyData['name']} có ${servicesSnapshot.docs.length} dịch vụ");

        for (var serviceDoc in servicesSnapshot.docs) {
          final serviceData = serviceDoc.data();

          allServices.add({
            'id': serviceDoc.id,
            ...serviceData,
            'companyId': companyId,
            'companyName': companyData['name'] ?? '',
            'companyType': companyData['type'] ?? '',
            'companyDescription': companyData['description'] ?? '',
            'price': serviceData['price'] ?? '',
          });

        }
      }

      print("Tổng số dịch vụ sau khi ghép company info: ${allServices.length}");

      setState(() {
        _allServices = allServices;

        _serviceTypeOptions = ["Tất cả"];
        _serviceTypeOptions.addAll({
          for (var c in companiesSnapshot.docs.map((e) => e.data()))
            c['type']
        }.whereType<String>().toSet());

        _selectedServiceType ??= "Tất cả"; // ✅ đảm bảo luôn có giá trị ban đầu
        _filterServices(); // ✅ gọi lọc ngay để áp dụng cả "Tất cả"
      });
    } catch (e) {
      print("Lỗi khi load services hoặc companies: $e");
    }
  }

  void _filterServices() {
    List<Map<String, dynamic>> filtered = _allServices;

    // Lọc theo tên công ty
    if (_searchCompanyName.isNotEmpty) {
      filtered = filtered
          .where((service) =>
          service['companyName']
              .toString()
              .toLowerCase()
              .contains(_searchCompanyName.toLowerCase()))
          .toList();
    }

    // Lọc theo loại dịch vụ
    if (_selectedServiceType != null && _selectedServiceType != "Tất cả") {
      filtered = filtered
          .where((service) =>
      service['companyType'].toString().trim().toLowerCase() ==
          _selectedServiceType!.toLowerCase())
          .toList();
    }

    // ✅ Lọc thêm theo trạng thái
    if (_selectedStatus != null && _selectedStatus != "Tất cả") {
      filtered = filtered
          .where((service) =>
      service['status'].toString().trim().toLowerCase() ==
          _selectedStatus!.toLowerCase())
          .toList();
    }

    setState(() {
      _filteredServices = filtered;
      currentPage = 1;
      _updatePaginatedServices();
    });
  }

  void _updatePaginatedServices() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > _filteredServices.length) {
        endIndex = _filteredServices.length;
      }

      paginatedServices = _filteredServices.sublist(startIndex, endIndex);
      totalPages = (_filteredServices.length / itemsPerPage).ceil();
      _updatePageNumbers();
      print("Hiển thị dịch vụ từ index $startIndex đến $endIndex");
      print("Số dịch vụ phân trang: ${paginatedServices.length}");
      print("Tổng số trang: $totalPages");
      print("Trang hiện tại: $currentPage");
      print("Danh sách số trang hiển thị: $pageNumbers");
    });
  }

  void _updatePageNumbers() {
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

  Future<void> _showServiceDetailDialog(BuildContext context, Map<String, dynamic> service) async{
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Thông tin chi tiết dịch vụ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                fontSize: 7.sp,
                fontFamily: "Oswald",
              ),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 80.w), // Giới hạn chiều ngang tối đa
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service['imageServiceUrl'] != null)
                    Container(
                      width: double.infinity, // Kéo full chiều ngang dialog
                      height: 200.h,
                      child: Image.network(
                        service['imageServiceUrl'],
                        fit: BoxFit.cover, // hoặc BoxFit.contain nếu bạn muốn ảnh không bị cắt
                      ),
                    ),
                  SizedBox(height: 30.h),
                  Text("Thời gian cập nhật: ${_formatTimestamp(service['timestamp'])}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Tên công ty: ${service['companyName'] ?? ''}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Loại dịch vụ: ${service['companyType'] ?? ''}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Mô tả: ${service['companyDescription'] ?? ''}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Giá: ${service['price'] ?? ''}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  if (service['fileLink'] != null)
                    Row(
                      children: [
                        Text('Thông tin chi tiết: ', style: TextStyle(fontSize: 4.sp)),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(service['fileLink'])),
                          child: Text(
                            'Xem tài liệu đính kèm',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 4.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 10.h),
                  Text("Trạng thái: ${service['status'] ?? ''}", style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Đóng', style: TextStyle(fontSize: 3.5.sp, color: Colors.white)),
            ),
          ],
        );
      },
    );
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Text(
                              'Danh sách yêu cầu',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Tìm kiếm theo tên công ty",
                                hintText: "Nhập tên công ty",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchCompanyName = value;
                                  _filterServices(); // Lọc danh sách khi nhập
                                });
                              },
                            ),
                          ),
                          Flexible(
                              flex:1,child: SizedBox(
                            height: 55.h,
                            width: 40.w,
                            child: ElevatedButton(
                              onPressed: ()
                              => exportServicesToExcel(_filteredServices),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                secondaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30.r),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black45,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload),
                                  SizedBox(width: 5.w,),
                                  Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.white),)
                                ],
                              ),
                            ),
                          )),
                          SizedBox(width:5.w),

                        ],
                      ),
                      SizedBox(height: 10.h),
                      // Dropdown lọc theo loại dịch vụ (service type)
                      Row(
                        children: [
                          Expanded(
                            child: buildFilterDropdown<String>(
                              label: "Chọn loại dịch vụ",
                              items: _serviceTypeOptions,
                              selectedValue: _selectedServiceType, // ✅ Sửa ở đây
                              onChanged: (value) {
                                setState(() {
                                  _selectedServiceType = value;
                                  _filterServices();
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: buildFilterDropdown<String>(
                              label: "Chọn trạng thái",
                              items: _statusOptions,
                              selectedValue: _selectedStatus, // ✅ Sửa ở đây
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                  _filterServices();
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      SizedBox(
                        height: MediaQuery.of(context).size.height - 150.h,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (_filteredServices.isEmpty) {
                              return Center(
                                child: Text(
                                  "Không có dịch vụ nào",
                                  style: TextStyle(fontSize: 4.sp, color: Colors.white),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth, // Đặt chiều rộng tối thiểu bằng chiều rộng cha
                                        maxWidth: constraints.maxWidth, // Đặt chiều rộng tối đa bằng chiều rộng cha
                                      ),
                                      child: CustomPaginatedTable(
                                        columns: [
                                          DataColumn(label: Text("Tên công ty", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Loại dịch vụ", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Mô tả", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Trạng thái", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Chi tiết", style: TextStyle(fontSize: 4.sp))),
                                        ],

                                        rows: paginatedServices.map((service) {
                                          return DataRow(cells: [
                                            DataCell(Text(service['companyName'] ?? '', style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(service['companyType'] ?? '', style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(service['companyDescription'] ?? '', style: TextStyle(fontSize: 4.sp))),
                                            DataCell(
                                              Row(
                                                children: [
                                                  Icon(
                                                    service['status'] == 'Đã duyệt'
                                                        ? Icons.check_circle
                                                        : service['status'] == 'Từ chối duyệt'
                                                        ? Icons.cancel
                                                        : Icons.hourglass_top,
                                                    color: service['status'] == 'Đã duyệt'
                                                        ? Colors.green
                                                        : service['status'] == 'Từ chối duyệt'
                                                        ? Colors.red
                                                        : Colors.orange,
                                                    size: 24, // nhỏ gọn hơn, không nên dùng sp cho icon
                                                  ),
                                                  SizedBox(width: 1.w),
                                                  Text(
                                                    service['status'] ?? 'Không rõ',
                                                    style: TextStyle(
                                                      color: service['status'] == 'Đã duyệt'
                                                          ? Colors.green
                                                          : service['status'] == 'Từ chối duyệt'
                                                          ? Colors.red
                                                          : Colors.orange,
                                                      fontSize: 4.sp, // hoặc 3.5.sp nếu bạn vẫn muốn theo responsive
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.info_outline),
                                                    onPressed: () {
                                                      _showServiceDetailDialog(context, service);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                          ]);
                                        }).toList(),
                                        rowsPerPage: itemsPerPage,
                                        availableRowsPerPage: [5, 10, 20, 50],
                                        // Các tùy chọn số dòng mỗi trang
                                        onRowsPerPageChanged: (value) {
                                          setState(() {
                                            itemsPerPage = value ??
                                                10; // Cập nhật số dòng mỗi trang
                                            currentPage = 1; // Reset về trang đầu
                                            _updatePaginatedServices();
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
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(fontSize: 4.sp),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item.toString(),
                  style: TextStyle(fontSize: 4.sp),
                ),
              );
            }).toList(),
            value: selectedValue == "Tất cả" ? null : selectedValue,
            onChanged: onChanged,
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Color(0xe2707070)),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200.h,
              width: 170.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
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







