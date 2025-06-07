import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/company_info.dart';
import 'package:do_an/src/models/information.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:do_an/src/resources/admin/ds_thongbao_mobile_page.dart' if (dart.library.html) 'ds_thongbao_web_page.dart';

class InfoListPage extends StatefulWidget {
  const InfoListPage({super.key});

  @override
  State<InfoListPage> createState() => _InfoListPageState();
}

class _InfoListPageState extends State<InfoListPage> {
  final AuthBloc _authBloc = AuthBloc();

  List<Information> _infoList = [];
  List<Information> _allInfoList = []; // Lưu danh sách đầy đủ của nhân viên

  String? _selectedInfoStatus;
  List<String> _infoStatusItems = ["Tất cả", "Cư dân", "Nhân viên", "Công ty dịch vụ ngoài"];

  String _searchQueryName = ""; // Biến lưu trữ giá trị tìm kiếm

  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  int itemsPerPage = 10;
  int currentPage = 1;
  int totalPages = 0;
  List<Information> paginatedInfos = [];
  List<int> pageNumbers = [];

  bool _isEditCompanyDialogShowing = false;
  bool _isDeleteCompanyDialogShowing = false;
  bool _isViewCompanyDialogShowing = false;

  void updatePaginatedCompanies() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > _infoList.length) {
        endIndex = _infoList.length;
      }

      paginatedInfos = _infoList.sublist(startIndex, endIndex);
      totalPages = (_infoList.length / itemsPerPage).ceil();
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
    _fetchInfo();
  }

  void _fetchInfo() async {
    final collections = {
      'information_residents': 'Cư dân',
      'information_staffs': 'Nhân viên',
      'information_companies': 'Công ty dịch vụ ngoài',
    };

    List<Information> allInfo = [];

    for (final entry in collections.entries) {
      final snapshot = await FirebaseFirestore.instance.collection(entry.key).get();
      allInfo.addAll(snapshot.docs.map((doc) => Information.fromFirestore(doc, entry.value)));
    }

    if (!mounted) return;

    setState(() {
      _allInfoList = allInfo;
      _infoList = allInfo;
    });
  }

  void _filterInfo() {
    List<Information> filteredList = _allInfoList;

    // Lọc theo loại (Cư dân, Nhân viên, Công ty...)
    if (_selectedInfoStatus != "Tất cả") {
      filteredList = filteredList.where((info) => info.source == _selectedInfoStatus).toList();
    }

    // Lọc thêm theo tên nếu cần
    if (_searchQueryName.isNotEmpty) {
      filteredList = filteredList
          .where((info) => info.title.toLowerCase().contains(_searchQueryName.toLowerCase()))
          .toList();
    }

    if (mounted) {
      setState(() {
        _infoList = filteredList;
        updatePaginatedCompanies(); // hoặc updatePaginatedInfo();
      });
    }
  }

  Future<void> showEditIncidentDialog(BuildContext context, Information info, VoidCallback onRefresh) async {
    final titleController = TextEditingController(text: info.title);
    final messageController = TextEditingController(text: info.message);

    bool isEditing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Nội dung thông báo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold,
                  fontSize: 7.sp,
                  color: Colors.blueAccent,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 140.r,
                          height: 140.r,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 0.5.w),
                          ),
                          child: info.imageUrl!.isNotEmpty
                              ? Image.network(info.imageUrl!, fit: BoxFit.cover)
                              : Image.asset('assets/default_avatar.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    StreamBuilder<String>(
                      stream: _authBloc.titleIncidentStream,
                      builder: (context, snapshot) => TextField(
                        controller: titleController,
                        enabled: isEditing,
                        style: TextStyle(fontSize: 3.5.sp),
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          errorText: snapshot.hasError ? snapshot.error as String : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 13.h),
                    StreamBuilder<String>(
                      stream: _authBloc.messageIncidentStream,
                      builder: (context, snapshot) => TextField(
                        controller: messageController,
                        enabled: isEditing,
                        style: TextStyle(fontSize: 3.5.sp),
                        decoration: InputDecoration(
                          labelText: 'Nội dung',
                          errorText: snapshot.hasError ? snapshot.error as String : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (isEditing) {
                      final isValid = _authBloc.isValidInformation(
                        titleController.text.trim(),
                        messageController.text.trim(),
                      );

                      if (!isValid) return;

                      LoadingDialog.showLoadingDialog(context, "Đang tải...");
                      try {
                        final updatedData = {
                          "title": titleController.text.trim(),
                          "message": messageController.text.trim(),
                          "lastEdited": FieldValue.serverTimestamp(),
                        };

                        // Danh sách các collection cần kiểm tra
                        final collections = [
                          "information_residents",
                          "information_staffs",
                          "information_companies",
                        ];

                        bool updated = false;

                        for (final collection in collections) {
                          final docRef = FirebaseFirestore.instance.collection(collection).doc(info.id);
                          final docSnap = await docRef.get();

                          if (docSnap.exists) {
                            await docRef.update(updatedData);
                            updated = true;
                            break; // chỉ cập nhật ở collection đầu tiên tìm thấy
                          }
                        }

                        if (!updated) {
                          print("❗ Không tìm thấy tài liệu trong các collection.");
                        }

                        Navigator.pop(context);
                        onRefresh();
                      } catch (e) {
                        print("❌ Error during update: $e");
                      } finally {
                        LoadingDialog.hideLoadingDialog(context);
                      }
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                  child: Text(isEditing ? "Lưu" : "Sửa", style: TextStyle(fontSize: 4.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showDeleteCompanyDialog(BuildContext context, CompanyInfo company, VoidCallback onRefresh) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Xác nhận xóa", style: TextStyle(fontSize: 5.sp),),
          content: Text("Bạn có chắc chắn muốn xóa công ty \"${company.name}\" không?", style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Đóng hộp thoại
              child: Text("Hủy", style: TextStyle(fontSize: 4.sp)),
            ),
            TextButton(
              onPressed: () async {
                LoadingDialog.showLoadingDialog(context, "Đang tải ...");
                try {
                  await FirebaseFirestore.instance.collection('companies').doc(company.companyId).update({
                    'isExit': true,
                    'leaveAt': Timestamp.now(),
                  });

                  Navigator.pop(context);
                  onRefresh();
                } catch (e) {
                  print("Error during deletion: $e");
                  LoadingDialog.hideLoadingDialog(context); // Đóng loading dialog nếu xảy ra lỗi
                }
              },
              child: Text("Xóa", style: TextStyle(color: Colors.red, fontSize: 4.sp)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showViewCompanyDialog(BuildContext context, CompanyInfo company, VoidCallback onRefresh) async{
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Thông tin công ty",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 7.sp,
              color: Colors.blueAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 140.r,
                      height: 140.r,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 0.5.w),
                      ),
                      child: company.imageUrl.isNotEmpty
                          ? Image.network(
                        company.imageUrl,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'assets/default_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Tên công ty: ${company.name}",
                  style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Email: ${company.email}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Số điện thoại: ${company.phone}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Địa chỉ: ${company.address}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Loại dịch vụ: ${company.type}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Mô tả: ${company.description}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Ngày nghỉ công việc: ${company.leaveAt != null ? DateFormat('dd/MM/yyyy – HH:mm').format(company.leaveAt!.toDate()) : "Chưa có"}',
                ),

              ],
            ),
          ),
          actions: [
            if (company.isExit)
              TextButton(
                onPressed: () async {
                  LoadingDialog.showLoadingDialog(context, "Đang tải...");
                  try {
                    await FirebaseFirestore.instance.collection('companies').doc(company.companyId).update({
                      'isExit': false,
                      'leaveAt': null,
                      'lastUpdatedd': Timestamp.now(),
                    });
                    LoadingDialog.hideLoadingDialog(context);
                    Navigator.pop(context);
                    onRefresh(); // Cập nhật lại UI
                  } catch (e) {
                    LoadingDialog.hideLoadingDialog(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi khi khôi phục tài khoản.", style: TextStyle(fontSize: 4.sp))),
                    );
                  }
                },
                child: Text("Khôi phục tài khoản", style: TextStyle(fontSize: 4.sp, color: Colors.green)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Đóng",
                style: TextStyle(fontSize: 4.sp),
              ),
            ),
          ],
        );
      },
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
                              'Danh sách thông báo',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),),
                            Flexible(flex:1,child: ElevatedButton(
                              onPressed: () => exportInfoToExcel(_infoList),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload),
                                  SizedBox(width: 5.w,),
                                  Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.white),)
                                ],
                              ),
                            ),),
                            SizedBox(width:5.w)
                          ],),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: buildFilterDropdown(
                                label: "Lọc theo đối tượng thông báo",
                                items: _infoStatusItems,
                                selectedValue: _selectedInfoStatus,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedInfoStatus = value;
                                    _filterInfo();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 20.w,),

                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Tìm kiếm theo tên thông báo",
                                  hintText: "Nhập tiêu đề thông báo",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQueryName = value;
                                    _filterInfo(); // Lọc danh sách khi nhập
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 20.w,),
                           ],),
                        SizedBox(height: 20.h,),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 360.h ,
                          child:  LayoutBuilder(
                            builder: (context,constraints){
                              return Column(
                                children: [

                                  if(_infoList.isEmpty)
                                    Expanded(child: Center(child: Text("Không có thông báo nào",style: TextStyle(
                                        fontSize: 4.sp, color: Colors.white),)))
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
                                              DataColumn(label: Text("Tiêu đề", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Thời gian đăng", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Lần chỉnh sửa gần nhất", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text('Đối tượng nhận', style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Thao tác", style: TextStyle(fontSize: 4.sp))),
                                            ],
                                            rows: _infoList.map((info) {
                                              return DataRow(cells: [
                                                DataCell(Text(info.title, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(dateFormatter.format(info.timestamp), style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(info.lastEdited != null ? dateFormatter.format(info.lastEdited!) : "-", style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(info.source, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.edit, color: Colors.blue),
                                                        onPressed: () async {
                                                          if (_isEditCompanyDialogShowing) return;
                                                          _isEditCompanyDialogShowing = true;
                                                          try {
                                                            await showEditIncidentDialog(context, info, _fetchInfo);
                                                          } finally {
                                                            _isEditCompanyDialogShowing = false;
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete, color: Colors.red),
                                                        onPressed: () async {
                                                          if (_isDeleteCompanyDialogShowing) return;
                                                          _isDeleteCompanyDialogShowing = true;
                                                          try {
                                                            // await showDeleteCompanyDialog(context, company, _fetchInfo);
                                                          } finally {
                                                            _isDeleteCompanyDialogShowing = false;
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                width: 152.w,
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







