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
import 'ds_nhanvien_mobile_page.dart' if (dart.library.html) 'ds_nhanvien_web_page.dart';

class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
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

  bool _isEditDialogShowing = false;
  bool _isDeleteDialogShowing = false;
  bool _isViewDialogShowing = false;

  final AuthBloc _authBloc = AuthBloc();

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
    _allStaffList = _staffList;
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

  Future<void> showViewStaffDialog(BuildContext context, Staff staff, VoidCallback onRefresh) async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Thông tin nhân viên",
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
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 70.r,
                    backgroundImage: staff.imageUrl.isNotEmpty
                        ? NetworkImage(staff.imageUrl)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                ),
                SizedBox(height: 20.h),
                buildInfoRow("Họ và tên:", staff.fullName),
                buildInfoRow("Email:", staff.email),
                buildInfoRow("Giới tính:", staff.gender),
                buildInfoRow(
                  "Ngày sinh:",
                  staff.birthDate != null
                      ? DateFormat('dd/MM/yyyy').format(staff.birthDate!)
                      : "Chưa cập nhật",
                ),
                buildInfoRow("CCCD:", staff.cccd),
                buildInfoRow("Địa chỉ:", staff.address),
                buildInfoRow("Số điện thoại:", staff.phone),
                buildInfoRow("Vị trí:", staff.position),
                if(staff.isExit)
                buildInfoRow(
                  "Ngày nghỉ công việc:",
                  staff.leaveAt != null
                      ? DateFormat('dd/MM/yyyy – HH:mm').format(staff.leaveAt!.toDate())
                      : "Chưa có",
                ),
              ],
            ),
          ),
          actions: [
            // Hiện nút "Khôi phục tài khoản" nếu nhân viên đã nghỉ
            if (staff.isExit)
              TextButton(
                onPressed: () async {
                  LoadingDialog.showLoadingDialog(context, "Đang tải...");
                  try {
                    await FirebaseFirestore.instance.collection('staffs').doc(staff.uid).update({
                      'isExit': false,
                      'leaveAt': null,
                      'lastUpdate': Timestamp.now(),
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
              child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
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

  Future<void> showEditDialog(BuildContext context, Staff staff, VoidCallback onRefresh) async{
    final nameController = TextEditingController(text: staff.fullName);
    final phoneController = TextEditingController(text: staff.phone);
    final positionController = TextEditingController(text: staff.position);
    final genderController = TextEditingController(text: staff.gender);
    final cccdController = TextEditingController(text: staff.cccd);
    final addressController = TextEditingController(text: staff.address);
    final emailController = TextEditingController(text: staff.email);
// Controller for birthDate (convert DateTime to String for TextField)
    final birthDateController = TextEditingController(
        text: staff.birthDate != null
            ? DateFormat('dd/MM/yyyy').format(staff.birthDate!)
            : '');
    bool isEditing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ChangeNotifierProvider(
              create: (_) => StaffImageProvider(),
              child: Consumer<StaffImageProvider>(
                builder: (context, imageProvider, _) {
                  return AlertDialog(
                    title: Text(
                      "Thông tin nhân viên",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.bold,
                        fontSize: 9.sp ,
                        color: Colors.blueAccent,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(left: 5.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // AVATAR ở trên cùng
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 80.r,
                                  backgroundImage: imageProvider.webImageBytes != null
                                      ? MemoryImage(imageProvider.webImageBytes!)
                                      : imageProvider.selectedImageFile != null
                                      ? FileImage(imageProvider.selectedImageFile!)
                                      : (staff.imageUrl.isNotEmpty
                                      ? NetworkImage(staff.imageUrl)
                                      : const AssetImage('assets/default_avatar.png') as ImageProvider),
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

                            SizedBox(height: 30.h),

                            // THÔNG TIN bên dưới
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Họ và tên + Email
                                Row(
                                  children: [
                                    Expanded(
                                      child: StreamBuilder<String>(
                                        stream: _authBloc.nameStaffStream,
                                        builder: (context, snapshot) => TextField(
                                          controller: nameController,
                                          enabled: isEditing,
                                          decoration: InputDecoration(
                                            labelText: 'Họ và tên',
                                            errorText: snapshot.hasError ? snapshot.error as String : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: StreamBuilder<String>(
                                        stream: _authBloc.emailStaffStream,
                                        builder: (context, snapshot) => TextField(
                                          controller: emailController,
                                          enabled: isEditing,
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            errorText: snapshot.hasError ? snapshot.error as String : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20.h),

                                // Ngày sinh + CCCD
                                Row(
                                  children: [
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: _authBloc.birthDateErrorStream,
                                        builder: (context, snapshot) {
                                          return GestureDetector(
                                            onTap: isEditing
                                                ? () async {
                                              final pickedDate = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime.now(),
                                              );
                                              if (pickedDate != null) {
                                                _authBloc.updateBirthDate1(pickedDate);
                                                birthDateController.text =
                                                    DateFormat('dd/MM/yyyy').format(pickedDate);
                                              }
                                            }
                                                : null,
                                            child: AbsorbPointer(
                                              absorbing: !isEditing,
                                              child: TextField(
                                                controller: birthDateController,
                                                enabled: isEditing,
                                                decoration: InputDecoration(
                                                  labelText: 'Ngày sinh',
                                                  errorText: snapshot.data,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: StreamBuilder<String>(
                                        stream: _authBloc.cccdStaffStream,
                                        builder: (context, snapshot) => TextField(
                                          controller: cccdController,
                                          enabled: isEditing,
                                          decoration: InputDecoration(
                                            labelText: 'CCCD',
                                            errorText: snapshot.hasError ? snapshot.error as String : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20.h),

                                // Giới tính + Vị trí
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomDropdownField(
                                        label: 'Giới tính',
                                        controller: genderController,
                                        options: ['Nam', 'Nữ', 'Khác'],
                                        isEditing: isEditing,
                                        fontSize: 3.5.sp,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: CustomDropdownField(
                                        label: 'Vị trí',
                                        controller: positionController,
                                        options: ['Nhân viên ghi chỉ số nước', 'Kĩ thuật viên'],
                                        isEditing: isEditing,
                                        fontSize: 3.5.sp,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20.h),

                                // Địa chỉ
                                StreamBuilder<String>(
                                  stream: _authBloc.addressStaffStream,
                                  builder: (context, snapshot) => TextField(
                                    controller: addressController,
                                    enabled: isEditing,
                                    decoration: InputDecoration(
                                      labelText: 'Địa chỉ',
                                      errorText: snapshot.hasError ? snapshot.error as String : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )



                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          if (isEditing) {
                            final isValid = _authBloc.isValidStaffUpdate(
                              nameController.text.trim(),
                              addressController.text.trim(),
                              cccdController.text.trim(),
                              genderController.text.trim(),
                              emailController.text.trim(),
                              phoneController.text.trim(),
                              positionController.text.trim(),
                              birthDateController.text.trim(), // Kiểm tra ngày sinh
                            );

                            if (!isValid) return;

                            LoadingDialog.showLoadingDialog(context, "Đang tải...");
                            try {
                              String? newImageUrl;

                              // Xử lý cập nhật ảnh đại diện
                              if (imageProvider.webImageBytes != null) {
                                if (staff.imageUrl.isNotEmpty) {
                                  final storageRef = FirebaseStorage.instance.refFromURL(staff.imageUrl);
                                  await storageRef.delete();
                                }

                                final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";
                                newImageUrl = await imageProvider.uploadSelectedImageAndGetUrl(staff.uid, uniqueFileName);
                              }

                              final updateData = <String, dynamic>{};
                              final updatedFields = <String, String>{}; // Lưu giá trị mới dưới dạng chuỗi

                              final Map<String, String> fieldLabels = {
                                'email': 'Email',
                                'fullName': 'Họ và tên',
                                'phone': 'Số điện thoại',
                                'position': 'Vị trí',
                                'cccd': 'CCCD',
                                'address': 'Địa chỉ',
                                'gender': 'Giới tính',
                                'birthDate': 'Ngày sinh',
                                'imageUrl': 'Ảnh đại diện'
                              };

                              void compareAndAdd(String key, dynamic newValue, dynamic oldValue) {
                                if (newValue != oldValue) {
                                  updateData[key] = newValue;
                                  updatedFields[key] = newValue.toString(); // Lưu giá trị mới dưới dạng chuỗi
                                }
                              }

                              compareAndAdd('email', emailController.text.trim(), staff.email);
                              compareAndAdd('fullName', nameController.text.trim(), staff.fullName);
                              compareAndAdd('phone', phoneController.text.trim(), staff.phone);
                              compareAndAdd('position', positionController.text.trim(), staff.position);
                              compareAndAdd('cccd', cccdController.text.trim(), staff.cccd);
                              compareAndAdd('address', addressController.text.trim(), staff.address);
                              compareAndAdd('gender', genderController.text.trim(), staff.gender);

                              final DateTime? newBirthDate = birthDateController.text.trim().isNotEmpty
                                  ? DateFormat('dd/MM/yyyy').parse(birthDateController.text.trim())
                                  : null;

                              compareAndAdd('birthDate', newBirthDate, staff.birthDate != null
                                  ? DateFormat('dd/MM/yyyy').format(staff.birthDate!)
                                  : null);

                              if (newImageUrl != null) {
                                updateData['imageUrl'] = newImageUrl;
                                updatedFields['imageUrl'] = 'Đã cập nhật ảnh'; // Add 'Đã cập nhật ảnh' to updatedFields
                              }

                              if (updateData.isNotEmpty) {
                                updateData['lastUpdate'] = Timestamp.now();
                                await FirebaseFirestore.instance.collection('staffs').doc(staff.uid).update(updateData);
                              }

                              if (updatedFields.isNotEmpty) {
                                final vietnameseUpdatedFields = updatedFields.map((key, value) {
                                  return MapEntry(fieldLabels[key] ?? key, value); // Sử dụng chú thích tiếng Việt nếu có
                                });

                                await sendUpdatedDetailEmailFromFlutter(
                                  uid: staff.uid,
                                  oldEmail: staff.email,
                                  newEmail: emailController.text.trim(),
                                  updatedFields: vietnameseUpdatedFields,
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

  /// Hàm hiển thị hộp thoại xác nhận xóa nhân viên
  Future<void> showDeleteStaffDialog(BuildContext context, Staff staff, VoidCallback onRefresh) async{
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("Xác nhận xóa", style: TextStyle(fontSize: 5.sp),),),
          content: Text("Bạn có chắc chắn muốn xóa nhân viên \"${staff.fullName}\" không?", style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Đóng hộp thoại
              child: Text("Hủy", style: TextStyle(fontSize: 4.sp)),
            ),
            TextButton(
              onPressed: () async {
                LoadingDialog.showLoadingDialog(context, "Đang tải ...");
                try {
                  await FirebaseFirestore.instance.collection('staffs').doc(staff.uid).update({
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

  Future<bool> sendUpdatedDetailEmailFromFlutter({
    required String uid,
    required String oldEmail,
    required String newEmail,
    required Map<String, String> updatedFields,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://sendupdateddetailemail1-ttrkrlo35a-uc.a.run.app"), // <-- Cloud Function URL đã deploy
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

  Future<bool> deleteStaffAccount(String uid) async {
    try {
      final response = await http.post(
        Uri.parse("https://deletestaffaccount-ttrkrlo35a-uc.a.run.app"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        print("✅ Xóa tài khoản $uid thành công.");
        return true;
      } else {
        print("❌ Lỗi khi xóa tài khoản $uid: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception khi gọi Cloud Function xóa user $uid: $e");
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
                          'Danh sách nhân viên',
                          style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 7.sp,
                          ),
                        ),),
                        Flexible(flex:2, child: TextField(
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
                              _filterStaff(); // Lọc danh sách khi nhập
                            });
                          },
                        ),),
                        Flexible(
                          flex:1,child: ElevatedButton(
                          onPressed: () => exportStaffsToExcel(_staffList),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload),
                              SizedBox(width: 5.w,),
                              Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),)
                            ],
                          ),
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
                            label: "Lọc theo trạng thái công việc",
                            items: _employmentStatusItems,
                            selectedValue: _selectedEmploymentStatus,
                            onChanged: (value) {
                              setState(() {
                                _selectedEmploymentStatus = value;
                                _filterStaff();
                              });
                            },
                          ),
                        ),

                        SizedBox(width: 20.w), // Khoảng cách giữa tiêu đề và tìm kiếm

                        Expanded(child:  buildFilterDropdown(
                      label: "Lọc theo chức vụ",
                      items: _positionItems,
                      selectedValue: _selectedPosition,
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                          _filterStaff();
                        });
                      },
                    ),),
                      SizedBox(width: 20.w), // Khoảng cách giữa tiêu đề và tìm kiếm
                      Expanded(child: buildFilterDropdown(
                        label: "Lọc theo trạng thái rảnh",
                        items: _statusItems,
                        selectedValue: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                            _filterStaff();
                          });
                        },
                      ),)],),
                    SizedBox(height: 20.h),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 150.h,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              if (_staffList.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "Không có nhân viên nào",
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
                                          DataColumn(label: Text("Họ và tên", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Email", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Giới tính", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Số điện thoại", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Địa chỉ", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Vị trí", style: TextStyle(fontSize: 4.sp))),
                                          DataColumn(label: Text("Thao tác", style: TextStyle(fontSize: 4.sp))),
                                        ],
                                        rows: paginatedStaffs.map((staff) {
                                          return DataRow(cells: [
                                            DataCell(Text(staff.fullName, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(staff.email, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(staff.gender, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(staff.phone, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(staff.address, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(staff.position, style: TextStyle(fontSize: 4.sp))),
                                            DataCell(
                                              Row(
                                                children: [
                                                  if (!staff.isExit) ...[
                                                    IconButton(
                                                      icon: Icon(Icons.edit, color: Colors.blue),
                                                      onPressed: () async {
                                                        if (_isEditDialogShowing) return;
                                                        _isEditDialogShowing = true;
                                                        try {
                                                          await showEditDialog(context, staff, _fetchStaff);
                                                        } finally {
                                                          _isEditDialogShowing = false;
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () async {
                                                        if (_isDeleteDialogShowing) return;
                                                        _isDeleteDialogShowing = true;
                                                        try {
                                                          await showDeleteStaffDialog(context, staff, _fetchStaff);
                                                        } finally {
                                                          _isDeleteDialogShowing = false;
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.info_outline, color: Colors.white),
                                                      onPressed: () async {
                                                        if (_isViewDialogShowing) return;
                                                        _isViewDialogShowing = true;
                                                        try {
                                                          await showViewStaffDialog(context, staff, _fetchStaff);
                                                        } finally {
                                                          _isViewDialogShowing = false;
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                  if (staff.isExit)
                                                    IconButton(
                                                      icon: Icon(Icons.info_outline, color: Colors.white),
                                                      onPressed: () async {
                                                        if (_isViewDialogShowing) return;
                                                        _isViewDialogShowing = true;
                                                        try {
                                                          await showViewStaffDialog(context, staff, _fetchStaff);
                                                        } finally {
                                                          _isViewDialogShowing = false;
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
                                            updatePaginatedStaffs();
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







