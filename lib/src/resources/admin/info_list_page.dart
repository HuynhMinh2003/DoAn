import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/information.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:do_an/src/resources/admin/info_list_mobile_page.dart' if (dart.library.html) 'info_list_web_page.dart';

import '../../../constants.dart';

class InfoListPage extends StatefulWidget {
  const InfoListPage({super.key});

  @override
  State<InfoListPage> createState() => _InfoListPageState();
}

class _InfoListPageState extends State<InfoListPage> {
  final AuthBloc _authBloc = AuthBloc();

  List<Information> _infoList = [];
  List<Information> _allInfoList = [];

  String? _selectedInfoStatus;
  List<String> _infoStatusItems = ["Tất cả", "Cư dân", "Nhân viên", "Công ty dịch vụ ngoài"];

  String _searchQueryName = "";

  final dateFormatter = DateFormat('dd/MM/yyyy - HH:mm');

  int itemsPerPage = 10;
  int currentPage = 1;
  int totalPages = 0;
  List<Information> paginatedInfos = [];
  List<int> pageNumbers = [];

  bool _isEditInfoDialogShowing = false;
  bool _isDeleteInfoDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

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

    if (_selectedInfoStatus != "Tất cả") {
      filteredList = filteredList.where((info) => info.source == _selectedInfoStatus).toList();
    }

    if (_searchQueryName.isNotEmpty) {
      filteredList = filteredList
          .where((info) => info.title.toLowerCase().contains(_searchQueryName.toLowerCase()))
          .toList();
    }

    if (mounted) {
      setState(() {
        _infoList = filteredList;
        updatePaginatedCompanies();
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
                OutlinedButton(
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

                        final collections = [
                          "information_residents",
                          "information_staffs",
                          "information_companies",
                        ];

                        bool updated = false;

                        for (final collection in collections) {
                          final docRef =
                          FirebaseFirestore.instance.collection(collection).doc(info.id);
                          final docSnap = await docRef.get();

                          if (docSnap.exists) {
                            await docRef.update(updatedData);
                            updated = true;
                            break;
                          }
                        }
                        Navigator.pop(context);
                        onRefresh();
                      } catch (e) {
                      } finally {
                        LoadingDialog.hideLoadingDialog(context);
                      }
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isEditing ? "Lưu" : "Sửa",
                    style: TextStyle(fontSize: 3.5.sp, color: Colors.white),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showDeleteIncidentDialog(BuildContext context, Information info, VoidCallback onRefresh) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(
            "Xác nhận xóa thông báo",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 7.sp,
              color: Colors.white,
            ),
          ),),
          content: Text(
            "Bạn có chắc chắn muốn xóa thông báo này không?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 4.sp),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp, color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () async {
                LoadingDialog.showLoadingDialog(context, "Đang xóa...");
                try {
                  final collections = [
                    "information_residents",
                    "information_staffs",
                    "information_companies",
                  ];

                  bool deleted = false;

                  for (final collection in collections) {
                    final docRef = FirebaseFirestore.instance.collection(collection).doc(info.id);
                    final docSnap = await docRef.get();

                    if (docSnap.exists) {
                      await docRef.delete();
                      deleted = true;
                      break;
                    }
                  }
                  Navigator.pop(context);
                  onRefresh();
                } catch (e) {
                } finally {
                  LoadingDialog.hideLoadingDialog(context);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Xóa", style: TextStyle(color: Colors.red, fontSize: 3.5.sp)),
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
                            Flexible(flex:4,child:  Text(
                              'Danh sách thông báo',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),),
                            SizedBox(width: 5.w,),
                            Flexible(flex:1,child: SizedBox(height: 55.h,width: 40.w,child: ElevatedButton(
                              onPressed: () => exportInfoToExcel(_infoList),
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
                            )),),

                            SizedBox(width: 1.w,),

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
                                    _filterInfo();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 20.w,),
                           ],),
                        SizedBox(height: 20.h,),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 150.h ,
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
                                            minWidth: constraints.maxWidth,
                                            maxWidth: constraints.maxWidth,
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
                                                          if (_isEditInfoDialogShowing) return;
                                                          _isEditInfoDialogShowing = true;
                                                          try {
                                                            await showEditIncidentDialog(context, info, _fetchInfo);
                                                          } finally {
                                                            _isEditInfoDialogShowing = false;
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete, color: Colors.red),
                                                        onPressed: () async {
                                                          if (_isDeleteInfoDialogShowing) return;
                                                          _isDeleteInfoDialogShowing = true;
                                                          try {
                                                            await showDeleteIncidentDialog(context, info, _fetchInfo);
                                                          } finally {
                                                            _isDeleteInfoDialogShowing = false;
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ]);
                                            }).toList(),
                                            rowsPerPage: itemsPerPage,
                                            availableRowsPerPage: [5, 10, 20, 50],
                                            onRowsPerPageChanged: (value) {
                                              setState(() {
                                                itemsPerPage = value ?? 10;
                                                currentPage = 1;
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
                    item.toString(),
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







