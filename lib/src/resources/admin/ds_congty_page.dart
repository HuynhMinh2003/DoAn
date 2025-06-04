import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/company_info.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:do_an/src/resources/admin/ds_congty_mobile_page.dart' if (dart.library.html) 'ds_congty_web_page.dart';

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

  bool _isEditCompanyDialogShowing = false;
  bool _isDeleteCompanyDialogShowing = false;
  bool _isViewCompanyDialogShowing = false;

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

  Future<void> showEditCompanyDialog(BuildContext context, CompanyInfo company, VoidCallback onRefresh) async{
    final nameController = TextEditingController(text: company.name);
    final phoneController = TextEditingController(text: company.phone);
    final addressController = TextEditingController(text: company.address);
    final emailController = TextEditingController(text: company.email);
    final typeController = TextEditingController(text: company.type);
    final describeController = TextEditingController(text: company.description);

    bool isEditing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ChangeNotifierProvider(
              create: (_) => CompanyImageProvider(),
              child: Consumer<CompanyImageProvider>(
                builder: (context, imageProvider, _) {
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
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r), // Bo góc nhẹ (có thể điều chỉnh bán kính)
                                  child: Container(
                                    width: 140.r, // Chiều rộng (tương tự với đường kính của CircleAvatar)
                                    height: 140.r, // Chiều cao (tương tự với đường kính của CircleAvatar)
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300, width: 0.5.w), // Tùy chỉnh viền
                                    ),
                                    child: imageProvider.webImageBytes != null
                                        ? Image.memory(
                                      imageProvider.webImageBytes!,
                                      fit: BoxFit.cover, // Đảm bảo ảnh khớp với hình vuông
                                    )
                                        : imageProvider.selectedImageFile != null
                                        ? Image.file(
                                      imageProvider.selectedImageFile!,
                                      fit: BoxFit.cover, // Đảm bảo ảnh khớp với hình vuông
                                    )
                                        : (company.imageUrl.isNotEmpty
                                        ? Image.network(
                                      company.imageUrl,
                                      fit: BoxFit.cover, // Đảm bảo ảnh khớp với hình vuông
                                    )
                                        : Image.asset(
                                      'assets/default_avatar.png',
                                      fit: BoxFit.cover, // Đảm bảo ảnh khớp với hình vuông
                                    )),
                                  ),
                                ),
                                if (isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt, color: Colors.blueAccent),
                                      onPressed: () async {
                                        await imageProvider.pickImage();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          StreamBuilder<String>(
                            stream: _authBloc.nameCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: nameController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp),
                              decoration: InputDecoration(
                                labelText: 'Tên công ty',
                                errorText: snapshot.hasError ? snapshot.error as String : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 13.h),
                          StreamBuilder<String>(
                            stream: _authBloc.emailCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: emailController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                errorText: snapshot.hasError ? snapshot.error as String : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 13.h),
                          StreamBuilder<String>(
                            stream: _authBloc.phoneCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: phoneController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp),
                              decoration: InputDecoration(
                                labelText: 'SĐT',
                                errorText: snapshot.hasError ? snapshot.error as String : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 13.h),
                          StreamBuilder<String>(
                            stream: _authBloc.addressCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: addressController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp),
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ',
                                errorText: snapshot.hasError ? snapshot.error as String : null,
                              ),
                            ),
                          ),
                          StreamBuilder<String>(
                            stream: _authBloc.typeCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: typeController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp ),
                              decoration: InputDecoration(
                                labelText: 'Loại dịch vụ',
                                errorText: snapshot.hasError ? snapshot.error as String : null,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          StreamBuilder<String>(
                            stream: _authBloc.describeCompanyStream,
                            builder: (context, snapshot) => TextField(
                              controller: describeController,
                              enabled: isEditing,
                              style: TextStyle(fontSize: 3.5.sp ),
                              decoration: InputDecoration(
                                labelText: 'Mô tả',
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
                            final isValid = _authBloc.isValidCompanySignUp(
                              nameController.text.trim(),
                              emailController.text.trim(),
                              phoneController.text.trim(),
                              typeController.text.trim(),
                              addressController.text.trim(),
                              describeController.text.trim(),
                            );

                            if (!isValid) return;

                            LoadingDialog.showLoadingDialog(context, "Đang tải...");
                            try {
                              String? newImageUrl;

                              if (imageProvider.webImageBytes != null) {
                                if (company.imageUrl.isNotEmpty) {
                                  final storageRef = FirebaseStorage.instance.refFromURL(company.imageUrl);
                                  await storageRef.delete();
                                }

                                final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";
                                newImageUrl = await imageProvider.uploadSelectedImageAndGetUrl(company.companyId!, uniqueFileName);
                              }

                              final updateData = <String, dynamic>{};
                              final updatedFields = <String, String>{}; // Initialize with an empty map

                              void compareAndAdd(String key, String newValue, String oldValue) {
                                if (newValue != oldValue) {
                                  updateData[key] = newValue;
                                  updatedFields[key] = newValue;
                                }
                              }

                              compareAndAdd('email', emailController.text.trim(), company.email);
                              compareAndAdd('name', nameController.text.trim(), company.name);
                              compareAndAdd('phone', phoneController.text.trim(), company.phone);
                              compareAndAdd('address', addressController.text.trim(), company.address);
                              compareAndAdd('type', typeController.text.trim(), company.type);
                              compareAndAdd('description', describeController.text.trim(), company.description);

                              if (newImageUrl != null) {
                                updateData['imageUrl'] = newImageUrl;
                                updatedFields['imageUrl'] = 'Đã cập nhật ảnh'; // Add 'Đã cập nhật ảnh' to updatedFields
                              }

                              if (updateData.isNotEmpty) {
                                updateData['lastUpdated'] = Timestamp.now();
                                await FirebaseFirestore.instance.collection('companies').doc(company.companyId!).update(updateData);
                              }

                              if (updatedFields.isNotEmpty) {
                                await sendUpdatedDetailEmailFromFlutter(
                                  uid: company.companyId!,
                                  oldEmail: company.email,
                                  newEmail: emailController.text.trim(),
                                  updatedFields: updatedFields,
                                );
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
                        child: Text(
                          isEditing ? "Lưu" : "Sửa",
                          style: TextStyle(fontSize: 4.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                      ),
                    ],
                  );
                },
              ),
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

  Future<bool> sendUpdatedDetailEmailFromFlutter({
    required String uid,
    required String oldEmail,
    required String newEmail,
    required Map<String, String> updatedFields,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://sendupdateddetailemail2-ttrkrlo35a-uc.a.run.app"), // <-- Cloud Function URL đã deploy
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'oldEmail': oldEmail,
          'newEmail': newEmail,
          'updatedFields': updatedFields,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Cập nhật & gửi email thông báo thành công.");
        return true;
      } else {
        print("❌ Lỗi từ server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception khi gọi Cloud Function: $e");
      return false;
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
                                      Expanded(child: Center(child: Text("Không có công ty nào",style: TextStyle(
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
                                              DataColumn(label: Text("Tên công ty", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Email", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Loại hình", style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text('Địa chỉ', style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text('Số điện thoại', style: TextStyle(fontSize: 4.sp))),
                                              DataColumn(label: Text("Thao tác", style: TextStyle(fontSize: 4.sp))),
                                            ],
                                            rows: _companyList.map((company) {
                                              return DataRow(cells: [
                                                DataCell(Text(company.name, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.email, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.type, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.address, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(company.phone, style: TextStyle(fontSize: 4.sp))),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      if (!company.isExit) ...[
                                                        IconButton(
                                                          icon: Icon(Icons.edit, color: Colors.blue),
                                                          onPressed: () async {
                                                            if (_isEditCompanyDialogShowing) return;
                                                            _isEditCompanyDialogShowing = true;
                                                            try {
                                                              await showEditCompanyDialog(context, company, _fetchCompany);
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
                                                              await showDeleteCompanyDialog(context, company, _fetchCompany);
                                                            } finally {
                                                              _isDeleteCompanyDialogShowing = false;
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                      if (company.isExit)
                                                        IconButton(
                                                          icon: Icon(Icons.info_outline, color: Colors.white),
                                                          onPressed: () async {
                                                            if (_isViewCompanyDialogShowing) return;
                                                            _isViewCompanyDialogShowing = true;
                                                            try {
                                                              await showViewCompanyDialog(context, company, _fetchCompany);
                                                            } finally {
                                                              _isViewCompanyDialogShowing = false;
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
                width: 100.w,
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







