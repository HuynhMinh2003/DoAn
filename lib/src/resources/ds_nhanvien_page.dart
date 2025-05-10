import 'dart:convert';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/models/staffs.dart';
import 'package:do_an/src/resources/provider/user_image_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:excel/excel.dart' as ex;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;


class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  final AuthBloc _authBloc = AuthBloc();

  String? _selectedPosition;
  List<String> _positionItems = [];
  List<Staff> _staffList = [];
  List<Staff> _allStaffList = []; // Lưu danh sách đầy đủ của nhân viên
  String? _selectedStatus;
  final List<String> _statusItems = ["Tất cả", "Đang rảnh", "Đang bận"];
  String _searchQuery = ""; // Biến lưu trữ giá trị tìm kiếm

  @override
  void initState() {
    super.initState();
    _fetchPositions();
    _fetchStaff();
  }

  void _fetchPositions() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("positions").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _positionItems = ["Tất cả"];
        _positionItems.addAll(data.values.map((e) => e.toString()));
      });
    }
  }

  void _fetchStaff() async {
    final snapshot = await FirebaseFirestore.instance.collection('staffs').get();
    final staffList = snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();
    setState(() {
      _allStaffList = staffList;  // Lưu danh sách đầy đủ
      _staffList = staffList;     // Hiển thị tất cả nhân viên ban đầu
    });
  }

  void _filterStaffByPosition(String? position) {
    if (position == "Tất cả" || position == null) {
      _staffList = _allStaffList; // Hiển thị tất cả nhân viên
    } else {
      _staffList = _allStaffList.where((staff) => staff.position == position).toList();
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

    // Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((staff) => staff.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _staffList = filteredList;
    });
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

  void showStaffDialog(BuildContext context, Staff staff, VoidCallback onRefresh) {
    final nameController = TextEditingController(text: staff.fullName);
    final phoneController = TextEditingController(text: staff.phone);
    final positionController = TextEditingController(text: staff.position);
    final genderController = TextEditingController(text: staff.gender);
    final cccdController = TextEditingController(text: staff.cccd);
    final addressController = TextEditingController(text: staff.address);
    final emailController = TextEditingController(text: staff.email);

    bool isEditing = false;
    bool isLoading = false;

    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ChangeNotifierProvider(
              create: (_) => UserImageProvider(),
              child: Consumer<UserImageProvider>(
                builder: (context, imageProvider, _) {
                  return AlertDialog(
                    title: Text(
                      "Thông tin nhân viên",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.bold,
                        fontSize: isLandscape ? 7.sp : 20.sp,
                        color: Colors.blueAccent,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading) Center(child: CircularProgressIndicator(),),
                          if (!isLoading) ...[
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 70.r,
                                    backgroundImage: imageProvider.webImageBytes != null
                                        ? MemoryImage(imageProvider.webImageBytes!)
                                        : imageProvider.selectedImageFile != null
                                        ? FileImage(imageProvider.selectedImageFile!)
                                        : (staff.imageUrl.isNotEmpty
                                        ? NetworkImage(staff.imageUrl)
                                        : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider),
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
                              stream: _authBloc.nameStaffStream,
                              builder: (context, snapshot) => TextField(
                                controller: nameController,
                                enabled: isEditing,
                                style: TextStyle(
                                    fontSize: isLandscape ? 3.5.sp : 15.sp),
                                decoration: InputDecoration(
                                  labelText: 'Họ và tên',
                                  errorText: snapshot.hasError
                                      ? snapshot.error as String
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 13.h),
                            StreamBuilder<String>(
                              stream: _authBloc.emailStaffStream,
                              builder: (context, snapshot) => TextField(
                                controller: emailController,
                                enabled: isEditing,
                                style: TextStyle(
                                    fontSize: isLandscape ? 3.5.sp : 15.sp),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  errorText: snapshot.hasError
                                      ? snapshot.error as String
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 13.h),
                            StreamBuilder<String>(
                              stream: _authBloc.phoneStaffStream,
                              builder: (context, snapshot) => TextField(
                                controller: phoneController,
                                enabled: isEditing,
                                style: TextStyle(
                                    fontSize: isLandscape ? 3.5.sp : 15.sp),
                                decoration: InputDecoration(
                                  labelText: 'SĐT',
                                  errorText: snapshot.hasError
                                      ? snapshot.error as String
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 13.h),
                            StreamBuilder<String>(
                              stream: _authBloc.cccdStaffStream,
                              builder: (context, snapshot) => TextField(
                                controller: cccdController,
                                enabled: isEditing,
                                style: TextStyle(
                                    fontSize: isLandscape ? 3.5.sp : 15.sp),
                                decoration: InputDecoration(
                                  labelText: 'CCCD',
                                  errorText: snapshot.hasError
                                      ? snapshot.error as String
                                      : null,
                                ),
                              ),
                            ),
                            StreamBuilder<String>(
                              stream: _authBloc.addressStaffStream,
                              builder: (context, snapshot) => TextField(
                                controller: addressController,
                                enabled: isEditing,
                                style: TextStyle(
                                    fontSize: isLandscape ? 3.5.sp : 15.sp),
                                decoration: InputDecoration(
                                  labelText: 'Địa chỉ',
                                  errorText: snapshot.hasError
                                      ? snapshot.error as String
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            CustomDropdownField(
                              label: 'Vị trí',
                              controller: positionController,
                              options: ['Nhân viên ghi chỉ số nước', 'Kĩ thuật viên'],
                              isEditing: isEditing,
                              fontSize: isLandscape ? 3.5.sp : 15.sp,
                            ),
                            CustomDropdownField(
                              label: 'Giới tính',
                              controller: genderController,
                              options: ['Nam', 'Nữ', 'Khác'],
                              isEditing: isEditing,
                              fontSize: isLandscape ? 3.5.sp : 15.sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Xác nhận xóa"),
                              content: Text("Bạn có chắc chắn muốn xóa nhân viên này?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Hủy",style: TextStyle(fontSize: 4.sp))),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Xóa", style: TextStyle(color: Colors.red,fontSize: 4.sp)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            if (staff.imageUrl.isNotEmpty) {
                              try {
                                final storageRef = FirebaseStorage.instance.refFromURL(staff.imageUrl);
                                await storageRef.delete();
                              } catch (e) {
                                print("⚠️ Không tìm thấy hoặc không thể xóa ảnh cũ: $e");
                              }
                            }

                            // Gọi hàm xóa tài khoản từ Firebase Authentication và Cloud Function
                            bool deleteSuccess = await deleteStaffAccount(staff.uid);

                            if (deleteSuccess) {
                              // Xóa thông tin nhân viên từ Firestore
                              await FirebaseFirestore.instance.collection('staffs').doc(staff.uid).delete();
                              Navigator.pop(context);
                              onRefresh();
                            } else {
                              // Nếu xóa không thành công, thông báo lỗi
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi xóa tài khoản.")));
                            }
                          }
                        },
                        child: Text("Xóa", style: TextStyle(color: Colors.red, fontSize: isLandscape ? 4.sp : 15.sp)),
                      ),
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
                            );

                            if (!isValid) {
                              setState(() => isLoading = false);
                              return;
                            }

                            setState(() => isLoading = true);

                            String? newImageUrl;

                            // ✅ Chỉ upload ảnh mới nếu có
                            if (imageProvider.webImageBytes != null) {
                              if (staff.imageUrl.isNotEmpty) {
                                try {
                                  final storageRef = FirebaseStorage.instance.refFromURL(staff.imageUrl);
                                  await storageRef.delete();
                                } catch (e) {
                                  print("⚠️ Không thể xóa ảnh cũ: $e");
                                }
                              }

                              final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";
                              newImageUrl = await imageProvider.uploadSelectedImageAndGetUrl(staff.uid, uniqueFileName);
                            }

                            // Tạo dữ liệu cập nhật
                            final updatedFields = <String, String>{};
                            final updateData = <String, dynamic>{};

                            // So sánh từng trường để chỉ gửi những gì thay đổi
                            void compareAndAdd(String key, String newValue, String oldValue) {
                              if (newValue != oldValue) {
                                updatedFields[key] = newValue;
                                updateData[key] = newValue;
                              }
                            }

                            compareAndAdd('email', emailController.text.trim(), staff.email);
                            compareAndAdd('fullName', nameController.text.trim(), staff.fullName);
                            compareAndAdd('phone', phoneController.text.trim(), staff.phone);
                            compareAndAdd('position', positionController.text.trim(), staff.position);
                            compareAndAdd('cccd', cccdController.text.trim(), staff.cccd);
                            compareAndAdd('address', addressController.text.trim(), staff.address);
                            compareAndAdd('gender', genderController.text.trim(), staff.gender);

                            if (newImageUrl != null) {
                              updateData['imageUrl'] = newImageUrl;
                            }

                            try {
                              // Cập nhật Firestore
                              await FirebaseFirestore.instance
                                  .collection('staffs')
                                  .doc(staff.uid)
                                  .update(updateData);

                              // Gửi email nếu có trường thay đổi
                              if (updatedFields.isNotEmpty) {
                                await sendUpdatedDetailEmailFromFlutter(
                                  uid: staff.uid,
                                  oldEmail: staff.email,
                                  newEmail: emailController.text.trim(),
                                  updatedFields: updatedFields,
                                );
                              }

                              Navigator.pop(context);
                              onRefresh();
                            } catch (e) {
                              print("❌ Lỗi khi cập nhật Firestore hoặc gửi email: $e");
                            }

                            setState(() => isLoading = false);
                          } else {
                            setState(() => isEditing = true);
                          }
                        },
                        child: Text(
                          isEditing ? "Lưu" : "Sửa",
                          style: TextStyle(fontSize: isLandscape ? 4.sp : 15.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Nút Đóng thêm vào đây
                        child: Text("Đóng", style: TextStyle(fontSize: 4.sp),),
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

  Future<void> exportStaffsToExcel(List<Staff> staffs) async {
    final excel = ex.Excel.createExcel(); // tạo file mới
    final sheet = excel['DanhSachNhanVien']; // tạo sheet

    // Dòng tiêu đề (Header)
    final headers = [
      ex.TextCellValue('Tên nhân viên'),
      ex.TextCellValue('Số điện thoại'),
      ex.TextCellValue('Địa chỉ'),
      ex.TextCellValue('Giới tính'),
      ex.TextCellValue('Số CCCD'),
      ex.TextCellValue('Chức vụ'),
      ex.TextCellValue('Email'),
    ];
    sheet.insertRowIterables(headers, 0); // Ghi dòng đầu tiên

    // Ghi từng dòng dữ liệu
    for (int i = 0; i < staffs.length; i++) {
      final apt = staffs[i];
      final row = [
        ex.TextCellValue(apt.fullName),
        ex.TextCellValue(apt.phone),
        ex.TextCellValue(apt.address),
        ex.TextCellValue(apt.gender),
        ex.TextCellValue(apt.cccd),
        ex.TextCellValue(apt.position),
        ex.TextCellValue(apt.email),
      ];
      sheet.insertRowIterables(row, i + 1);
    }

    // Xuất file
    final fileBytes = excel.encode();
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "DanhSachNhanVien.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
        padding: EdgeInsets.only(left: 30.w, right: 20.w, top: 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Danh sách nhân viên',
              style: TextStyle(
                fontFamily: "Oswald",
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => exportStaffsToExcel(_staffList),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload),
                  SizedBox(width: 5.w,),
                  Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.black),)
                ],
              ),
            ),
            SizedBox(height: 30.h),
            SizedBox(
              height: MediaQuery.of(context).size.height - 360.h ,
              child:  Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextField(
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
                            ),
                          ),

                          SizedBox(height: 50.h,),
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
                          SizedBox(height: 50.h),
                          buildFilterDropdown(
                            label: "Lọc theo trạng thái",
                            items: _statusItems,
                            selectedValue: _selectedStatus,
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                                _filterStaff();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  VerticalDivider(
                    color: Colors.grey, // Màu của đường ngăn cách
                    thickness: 0.2.w, // Độ dày của đường ngăn cách
                    width: 40.w, // Chiều rộng tổng thể của vùng ngăn cách (bao gồm cả padding nếu có)
                  ),

                  Expanded(
                    child: _staffList.isEmpty
                        ? const Center(child: Text("Không có nhân viên nào"))
                        : SingleChildScrollView(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 30.h,
                          crossAxisSpacing: 5.w,
                          childAspectRatio: 6 / 2.5,
                        ),
                        itemCount: _staffList.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final staff = _staffList[index];
                          return GestureDetector(
                            onTap: () => showStaffDialog(context, staff, (){
                              _fetchStaff();
                            }),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(1.w,25.h,1.w,0.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 6.r,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(width: 5.w),
                                        Stack(
                                          children: [
                                            // Ảnh nhân viên
                                            Container(
                                              width: 17.w,
                                              height: 80.h,
                                              child: CircleAvatar(
                                                radius: 8.r,
                                                backgroundImage: staff.imageUrl.isNotEmpty
                                                    ? NetworkImage(staff.imageUrl)
                                                    : null,
                                                child: staff.imageUrl.isEmpty
                                                    ? Icon(Icons.person, size: 40.w)
                                                    : null,
                                              ),
                                            ),
                                            // Trạng thái hoạt động
                                            Positioned(
                                              bottom: 0, // Căn dưới cùng
                                              right: 0, // Căn phải
                                              child: Container(
                                                width: 5.w, // Kích thước vòng tròn trạng thái
                                                height: 5.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: staff.isFree ? Colors.green : Colors.red, // Xanh lá nếu isFree, đỏ nếu không
                                                  border: Border.all(
                                                    color: Colors.white, // Viền trắng để tách khỏi ảnh
                                                    width: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 5.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                staff.fullName,
                                                style: TextStyle(
                                                  fontFamily: "Oswald",
                                                  fontSize: 4.5.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 10.h),
                                              Text(
                                                staff.position,
                                                style: TextStyle(
                                                  fontSize: 3.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

            )
          ],
        ),
      )
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
                style: TextStyle(color: Colors.black, fontSize: 4.sp ),
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
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 147.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
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







