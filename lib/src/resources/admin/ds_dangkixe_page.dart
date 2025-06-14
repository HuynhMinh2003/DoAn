import 'package:flutter/foundation.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants.dart';
import '../../../custom_paginated_table.dart';
import 'package:do_an/src/resources/admin/ds_dangkixe_mobile_page.dart' if (dart.library.html) 'ds_dangkixe_web_page.dart';

class RegistrationListPage extends StatefulWidget {
  const RegistrationListPage({super.key});

  @override
  State<RegistrationListPage> createState() => _RegistrationListPageState();
}

class _RegistrationListPageState extends State<RegistrationListPage> {
  String? _selectedVehicleType = "Tất cả";
  String _searchLicensePlate = "";
  String? _selectedCancellation = "Tất cả";

  final Map<String, String> _vehicleTypeMap = {
    'Tất cả': 'Tất cả',
    'motorbike_roofed': 'Xe máy (có mái che)',
    'motorbike_unroofed': 'Xe máy (không mái che)',
    'bike_roofed': 'Xe đạp (có mái che)',
    'bike_unroofed': 'Xe đạp (không mái che)',
    'car_roofed': 'Ô tô (có mái che)',
    'car_unroofed': 'Ô tô (không mái che)',
  };

  late List<String> _vehicleTypeOptions = _vehicleTypeMap.keys.toList();

  final List<String> _cancellationOptions = [
    'Tất cả',
    'Chưa huỷ',
    'Đã huỷ',
  ];

  List<Map<String, dynamic>> _allRegis = [];
  List<Map<String, dynamic>> _filteredRegis = [];

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 0;
  List<Map<String, dynamic>> paginatedRegis = [];
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
    _loadParkingRegistrations();
  }

  Future<void> _loadParkingRegistrations() async {
    try {
      final contractsSnapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .get();

      List<Map<String, dynamic>> allRegistrations = [];

      for (var contractDoc in contractsSnapshot.docs) {
        final contractId = contractDoc.id;

        final registrationSnapshot = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('parkingRegistrations')
            .get();

        for (var regDoc in registrationSnapshot.docs) {
          final regData = regDoc.data();

          allRegistrations.add({
            'contractId': contractId,
            'registrationId': regDoc.id,
            ...regData,
          });
        }
      }

      print("Tổng số đăng ký xe: ${allRegistrations.length}");

      setState(() {
        _allRegis = allRegistrations;
        _filteredRegis = allRegistrations;
        currentPage = 1;
        _updatePaginatedRegis();
      });
    } catch (e) {
      print("Lỗi khi load parking registrations: $e");
    }
  }

  void _filterRegis() {
    List<Map<String, dynamic>> filtered = _allRegis;

    // Lọc theo biển số xe
    if (_searchLicensePlate.isNotEmpty) {
      filtered = filtered
          .where((reg) =>
          reg['licensePlate']
              .toString()
              .toLowerCase()
              .contains(_searchLicensePlate.toLowerCase()))
          .toList();
    }

    // Lọc theo loại xe
    if (_selectedVehicleType != null && _selectedVehicleType != "Tất cả") {
      filtered = filtered
          .where((reg) =>
      reg['vehicleType']
          .toString()
          .toLowerCase()
          .trim() ==
          _selectedVehicleType!.toLowerCase())
          .toList();
    }

    // Lọc theo đã huỷ hay chưa
    if (_selectedCancellation != null && _selectedCancellation != "Tất cả") {
      if (_selectedCancellation == "Đã huỷ") {
        filtered = filtered
            .where((reg) => reg['isCancelled'] == true)
            .toList();
      } else if (_selectedCancellation == "Chưa huỷ") {
        filtered = filtered
            .where((reg) => reg['isCancelled'] != true)
            .toList();
      }
    }

    setState(() {
      _filteredRegis = filtered;
      currentPage = 1;
      _updatePaginatedRegis();
    });
  }

  void _updatePaginatedRegis() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > _filteredRegis.length) {
      endIndex = _filteredRegis.length;
    }

    paginatedRegis = _filteredRegis.sublist(startIndex, endIndex);
    totalPages = (_filteredRegis.length / itemsPerPage).ceil();
    _updatePageNumbers();

    print("Hiển thị dịch vụ từ index $startIndex đến $endIndex");
    print("Số dịch vụ phân trang: ${paginatedRegis.length}");
    print("Tổng số trang: $totalPages");
    print("Trang hiện tại: $currentPage");
    print("Danh sách số trang hiển thị: $pageNumbers");

    setState(() {});
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
          title: Center(child: Text('Thông tin chi tiết dịch vụ',style: TextStyle(fontSize: 7.sp,fontFamily: "Oswald"),),),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service['imageServiceUrl'] != null)
                  Center(child: Image.network(service['imageServiceUrl'], height: 150),),
                SizedBox(height: 30.h),
                Text("Thời gian cập nhật: ${_formatTimestamp(service['timestamp'])}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
                Text("Tên công ty: ${service['companyName'] ?? ''}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
                Text("Loại dịch vụ: ${service['companyType'] ?? ''}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
                Text("Mô tả: ${service['companyDescription'] ?? ''}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
                Text("Giá: ${service['price'] ?? ''}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
                if (service['fileLink'] != null)
                  Row(
                    children: [
                      Text('Thông tin chi tiết: ',style: TextStyle(fontSize: 4.sp)),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(service['fileLink'])),
                        child: Text(
                          'Xem tài liệu đính kèm',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline,fontSize: 4.sp,fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 10.h),
                Text("Trạng thái: ${service['status'] ?? ''}",style: TextStyle(fontSize: 4.sp),),
                SizedBox(height: 10.h),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng',style: TextStyle(fontSize: 4.sp)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateServiceStatus(String serviceId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(serviceId)
          .update({'status': newStatus});

      setState(() {
        _loadParkingRegistrations(); // Hoặc bạn gọi lại hàm load danh sách
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
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
                              'Danh sách đăng ký xe',
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
                                labelText: "Tìm theo biển số",
                                hintText: "Nhập biển số",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchLicensePlate = value;
                                  _filterRegis();
                                });
                              },
                            ),
                          ),
                          Flexible(
                            flex:1,child: SizedBox(height: 55.h,width: 40.w,child: ElevatedButton(
                            onPressed: () => exportRegistrationsToExcel(_filteredRegis),
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
                          ),)),
                          SizedBox(width:5.w),

                        ],
                      ),
                      SizedBox(height: 10.h),
                      // Dropdown lọc theo loại dịch vụ (service type)
                      Row(
                        children: [
                          Expanded(
                            child: buildFilterDropdown1<String>(
                              label: "Loại xe",
                              items: _vehicleTypeOptions,
                              selectedValue: _selectedVehicleType == "Tất cả" ? null : _selectedVehicleType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value ?? "Tất cả";
                                  _filterRegis();
                                });
                              },
                              itemLabels: _vehicleTypeMap, // 👈 Truyền map tiếng Việt vào đây
                            ),
                          ),

                          SizedBox(width: 10.w),
                          Expanded(
                            child: buildFilterDropdown<String>(
                              label: "Tình trạng xe",
                              items: _cancellationOptions,
                              selectedValue: _selectedCancellation == "Tất cả" ? null : _selectedCancellation,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCancellation = value ?? "Tất cả";
                                  _filterRegis();
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
                            if (_filteredRegis.isEmpty) {
                              return Center(
                                child: Text(
                                  "Không có xe nào",
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
                                          DataColumn(label: Text("Biển số xe", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Loại xe", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Thời gian đăng ký", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Trạng thái", style: TextStyle(fontSize: 4.sp))),
                                        ],
                                        rows: paginatedRegis.map((registration) {
                                          final vehicleTypeKey = registration['vehicleType'] ?? '';
                                          final vehicleTypeVN = _vehicleTypeMap[vehicleTypeKey] ?? vehicleTypeKey;

                                          return DataRow(cells: [
                                            DataCell(Text(registration['licensePlate'] ?? '', style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(vehicleTypeVN, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(_formatTimestamp(registration['registeredAt']), style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(
                                              registration['canceledAt'] != null
                                                  ? 'Đã huỷ (${_formatTimestamp(registration['canceledAt'])})'
                                                  : 'Chưa huỷ',
                                              style: TextStyle(fontSize: 4.sp),
                                            )),
                                          ]);
                                        }).toList(),
                                      )
                                      ,
                                    ),
                                  ),
                                ),
                                // Phân trang
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: pageNumbers.map((page) {
                                    final isSelected = page == currentPage;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSelected ? Colors.blue : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            currentPage = page;
                                            _updatePaginatedRegis();
                                          });
                                        },
                                        child: Text(
                                          "$page",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }).toList(),
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

  Widget buildFilterDropdown1<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    Map<T, String>? itemLabels, // 👈 Thêm map ánh xạ giá trị → nhãn
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
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabels?[item] ?? item.toString(), // 👈 Dùng nhãn nếu có
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







