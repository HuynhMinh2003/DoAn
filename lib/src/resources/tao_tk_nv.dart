import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddAccountStaffPage extends StatefulWidget {
  const AddAccountStaffPage({super.key});

  @override
  State<AddAccountStaffPage> createState() => _AddAccountStaffPageState();
}

class _AddAccountStaffPageState extends State<AddAccountStaffPage> {
  final TextEditingController _nameStaffController = TextEditingController();
  final TextEditingController _emailStaffController = TextEditingController();
  final TextEditingController _phoneStaffController = TextEditingController();
  final TextEditingController _cccdStaffController = TextEditingController();
  final TextEditingController _addressStaffController = TextEditingController();
  DateTime? birthDate;

  final AuthBloc _authBloc = AuthBloc();

  String? _selectedRole;

  String? selectedGender;

  String? _imageUrl;

  List<String> _roleItems = [];

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem widget có còn mounted không trước khi gọi resetImage
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final avatarProvider = Provider.of<StaffImageProvider>(context, listen: false);
        avatarProvider.resetImage();
      });
    }

    _fetchPositions();
  }

  void _fetchPositions() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("positions").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        _roleItems = data.values.map((e) => e.toString()).toList(); // lấy danh sách các "positions"
      });
    }
  }

  @override
  void dispose() {
    _nameStaffController.dispose();
    _emailStaffController.dispose();
    _phoneStaffController.dispose();
    _cccdStaffController.dispose();
    _addressStaffController.dispose();
    _authBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 50.w, right: 40.w, top: 40.h),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20.h,
                        ),
                        Text(
                          'Tài khoản mới cho nhân viên',
                          style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 50.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 25.w,),
                            // Bên trái: ảnh
                            Center(
                              child: Consumer<StaffImageProvider>(
                                builder: (context, avatarProvider, child) {
                                  String? avatarUrl = avatarProvider.avatarUrl;
                                  bool hasImage = avatarUrl != null ||
                                      avatarProvider.selectedImageFile != null ||
                                      avatarProvider.webImageBytes != null;

                                  Widget _buildAvatarImage() {
                                    if (avatarProvider.webImageBytes != null) {
                                      return Image.memory(
                                        avatarProvider.webImageBytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    } else if (avatarProvider.selectedImageFile != null) {
                                      return Image.file(
                                        avatarProvider.selectedImageFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    } else if (avatarUrl != null) {
                                      return Image.network(
                                        '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Icon(Icons.error, color: Colors.red)),
                                      );
                                    } else {
                                      return Icon(Icons.add_a_photo, size: 20.sp, color: Colors.grey);
                                    }
                                  }

                                  double avatarSize = min(300.w, 300.h);

                                  return SizedBox(
                                    width: avatarSize, // ➔ Chiều ngang avatar
                                    height: avatarSize + 40.h, // ➔ Chiều cao avatar + label
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipOval(
                                          child: Material(
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () async {
                                                final provider = Provider.of<StaffImageProvider>(context, listen: false);
                                                await provider.pickImage();
                                                await Future.delayed(const Duration(milliseconds: 300));

                                                if (kIsWeb) {
                                                  print("🧾 Ảnh web đã chọn: ${provider.webImageBytes != null ? "Đã có dữ liệu bytes" : "null"}");
                                                } else {
                                                  print("🧾 Ảnh file đã chọn: ${provider.selectedImageFile?.path ?? "null"}");
                                                }

                                                if (provider.selectedImageFile == null &&
                                                    provider.webImageBytes == null &&
                                                    avatarUrl == null) {
                                                  MsgDialog.showMsgDialog(context, "Lỗi", "Chưa chọn ảnh hoặc không tải được ảnh ");
                                                }
                                              },
                                              splashColor: Colors.grey.withOpacity(0.1),
                                              highlightColor: Colors.transparent,
                                              radius: avatarSize / 2,
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                width: avatarSize,
                                                height: avatarSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey.shade300, width: 0.5.w),
                                                ),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 300),
                                                  child: _buildAvatarImage(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            margin: EdgeInsets.only(top: 8.h),
                                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(20.r),
                                            ),
                                            child: Text(
                                              hasImage ? 'Thay đổi' : 'Thêm ảnh',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 4.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 30.w,),
                            // Bên phải: form login
                            Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTextField(
                                      controller: _nameStaffController,
                                      label: 'Họ và tên:',
                                      stream: _authBloc.nameStaffStream,
                                    ),
                                    _buildTextField(
                                      controller: _phoneStaffController,
                                      label: 'Số điện thoại:',
                                      stream: _authBloc.phoneStaffStream,
                                    ),
                                    _buildTextField(
                                      controller: _cccdStaffController,
                                      label: 'Số CCCD:',
                                      stream: _authBloc.cccdStaffStream,
                                    ),
                                    _buildDatePickerButton(),
                                    _buildTextField(
                                      controller: _addressStaffController,
                                      label: 'Nơi ở:',
                                      stream: _authBloc.addressStaffStream,
                                    ),
                                    _buildTextField(
                                      controller: _emailStaffController,
                                      label: 'Email:',
                                      stream: _authBloc.emailStaffStream,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: buildFilterDropdown(
                                          label: "Giới tính",
                                          items: ["Nam", "Nữ", "Khác"],
                                          selectedValue: selectedGender,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedGender = value;
                                            });
                                          },
                                        ),),
                                        SizedBox(width: 5.w,),
                                        Expanded(child: buildFilterDropdown(
                                          label: "Vai trò",
                                          items: _roleItems,
                                          selectedValue: _selectedRole,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedRole = value;
                                            });
                                          },
                                        ),)
                                      ],
                                    )
                                  ],
                                )),
                          ],
                        ),
                        SizedBox(height: 50.h,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Phân bố nút cách đều
                          children: [
                            SizedBox(width: 20.w), // Tùy chọn nếu bạn muốn có khoảng cách giữa các nút
                            Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _onSignUpStaffClicked();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor, // Màu xanh dương sáng
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    "Tạo tài khoản",
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 7.sp,
                                      color: Colors.white, // Màu chữ trắng
                                      height: 1.h,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 60.w), // Tùy chọn nếu bạn muốn có khoảng cách giữa các nút
                            Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Xóa tất cả thông tin trong các trường nhập
                                    _nameStaffController.clear();
                                    _emailStaffController.clear();
                                    _phoneStaffController.clear();
                                    _emailStaffController.clear();
                                    _cccdStaffController.clear();
                                    _addressStaffController.clear();

                                    // Reset ảnh
                                    final avatarProvider = Provider.of<StaffImageProvider>(context, listen: false);
                                    avatarProvider.resetImage();  // Reset ảnh

                                    setState(() {
                                      selectedGender = null;  // Hoặc giá trị mặc định bạn muốn
                                    });
                                    // Reset vai trò nếu cần
                                    setState(() {
                                      _selectedRole = null;  // Hoặc giá trị mặc định bạn muốn
                                    });
                                    setState(() {
                                      birthDate = null; // Đặt biến `birthDate` về null
                                    });
                                    _authBloc.updateBirthDate(null); // Cập nhật giá trị trong Stream về null
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor, // Màu xám trung tính
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    "Hủy",
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 7.sp,
                                      color: Colors.white, // Màu chữ trắng
                                      height: 1.h,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20.w), // Tùy chọn nếu bạn muốn có khoảng cách giữa các nút
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onSignUpStaffClicked() async {
    if (_selectedRole == null) {
      MsgDialog.showMsgDialog(context, "Lỗi", "Vui lòng chọn vai trò");
      return;
    }
    if (selectedGender == null) {
      MsgDialog.showMsgDialog(context, "Lỗi", "Vui lòng chọn giới tính");
      return;
    }

    var isValidStaff = _authBloc.isValidStaffSignUp(
      _nameStaffController.text,
      _addressStaffController.text,
      _cccdStaffController.text,
      birthDate,
      selectedGender!,
      _emailStaffController.text,
      _phoneStaffController.text,
      _selectedRole!,
    );

    if (!isValidStaff) return;

    final imageProvider = Provider.of<StaffImageProvider>(context, listen: false);
    final hasImage = (kIsWeb && imageProvider.webImageBytes != null) ||
        (!kIsWeb && imageProvider.selectedImageFile != null);

    if (!hasImage) {
      MsgDialog.showMsgDialog(context, "Lỗi", "Bạn chưa chọn ảnh. Vui lòng chọn lại");
      return;
    }

    LoadingDialog.showLoadingDialog(context, 'Đang tạo tài khoản ...');

    try {
      // 1. Gọi Cloud Function tạo tài khoản trước
      final url = Uri.parse("https://createstaffaccount-ttrkrlo35a-uc.a.run.app");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailStaffController.text.trim(),
          "fullName": _nameStaffController.text.trim(),
          "address": _addressStaffController.text.trim(),
          "birthDate": birthDate != null
              ? "${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}"
              : null, // Đảm bảo birthDate không bị null
          "gender": selectedGender!,
          "cccd": _cccdStaffController.text.trim(),
          "phone": _phoneStaffController.text.trim(),
          "position": _selectedRole!,
        }),
      );

      if (response.statusCode != 200) {
        LoadingDialog.hideLoadingDialog(context);
        MsgDialog.showMsgDialog(context, "Thất bại", "Không thể tạo tài khoản: ${response.body}");
        return;
      }

      // 2. Nếu thành công → lấy `uid` từ phản hồi
      final responseBody = jsonDecode(response.body);
      final userId = responseBody['uid']; // Lấy uid từ phản hồi
      final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";

      final imageUrl = await imageProvider.uploadSelectedImageAndGetUrl(userId, uniqueFileName);

      _imageUrl = imageUrl;

      // 3. Cập nhật Firestore với imageUrl nếu cần
      await FirebaseFirestore.instance.collection("staffs").doc(userId).set({
        "imageUrl": imageUrl,
        "email": _emailStaffController.text.trim(),
        "fullName": _nameStaffController.text.trim(),
        "birthDate": birthDate,
        "phone": _phoneStaffController.text.trim(),
        "cccd": _cccdStaffController.text.trim(),
        "address": _addressStaffController.text.trim(),
        "position": _selectedRole!,
        "gender": selectedGender!,
      }, SetOptions(merge: true));

      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Thành công", "Tạo tài khoản nhân viên thành công.");
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Lỗi", "Không thể tạo tài khoản: $e");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) {
          return TextField(
            controller: controller,
            style: TextStyle(fontSize: 4.sp),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 4.sp
              ),
              errorText: snapshot.hasError ? snapshot.error as String : null,
              contentPadding:
              EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
              border: OutlineInputBorder(
                borderSide: BorderSide(width: 1.w),
                borderRadius: BorderRadius.all(Radius.circular(30.r)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildFilterDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                label+":",
                style: TextStyle(fontSize: 4.sp),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical:2.h,horizontal: 10.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 70.w,
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
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 2.h),
      child: StreamBuilder<DateTime?>(
        stream: _authBloc.birthDateStaffStream,
        builder: (context, snapshot) {
          final hasError = snapshot.hasError;

          return SizedBox(
            height: 60.h, // đủ chỗ cho cả button + lỗi
            child: Stack(
              clipBehavior: Clip.none, // cho lỗi có thể "tràn" ra ngoài
              children: [
                SizedBox(
                  height: 50.h,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          birthDate = picked;
                          _authBloc.updateBirthDate(picked);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bgColor, // Thay đổi màu nền thành màu xám
                      elevation: 0,
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        side: BorderSide(
                          color: hasError ? Color(0xFFD32F2F) : Colors.white,
                          width: 0.17.w,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (birthDate != null)
                          Text(
                            'Ngày sinh:',
                            style: TextStyle(
                              fontSize: 3.sp,
                            ),
                          ),
                        Text(
                          birthDate == null
                              ? "Ngày sinh:"
                              : "${birthDate!.toLocal()}".split(' ')[0],
                          style: TextStyle(
                            fontSize: 4.sp, color: Colors.grey
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (hasError)
                  Positioned(
                    left: 10.w,
                    bottom: -18.h, // tràn ra ngoài một chút
                    child: Text(
                      snapshot.error as String,
                      style: TextStyle(color: Colors.red, fontSize: 3.sp),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
