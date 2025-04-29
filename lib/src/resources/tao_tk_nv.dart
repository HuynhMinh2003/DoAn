import 'dart:math';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/user_image_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddAccountStaffPage extends StatefulWidget {
  const AddAccountStaffPage({super.key});

  @override
  State<AddAccountStaffPage> createState() => _AddAccountStaffPageState();
}

class _AddAccountStaffPageState extends State<AddAccountStaffPage> {
  final TextEditingController _nameStaffController = TextEditingController();
  final TextEditingController _emailStaffController = TextEditingController();
  final TextEditingController _phoneStaffController = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  String? _selectedRole;

  String? _imageUrl;

  List<String> _roleItems = [];

  @override
  void initState() {
    super.initState();
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
    _authBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset('assets/images/two_circle.png', width: 160),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 50.w, right: 50.w, top: 140.h),
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
                          height: 30.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 25.w,),
                            // Bên trái: ảnh
                            Center(
                              child: Consumer<UserImageProvider>(
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
                                                final provider = Provider.of<UserImageProvider>(context, listen: false);
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
                            SizedBox(width: 60.w,),
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
                                      controller: _emailStaffController,
                                      label: 'Email:',
                                      stream: _authBloc.emailStaffStream,
                                    ),
                                    buildFilterDropdown(
                                      label: "Vai trò",
                                      items: _roleItems,
                                      selectedValue: _selectedRole,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRole = value;
                                        });
                                      },
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        SizedBox(height: 70.h,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Phân bố nút cách đều
                          children: [
                            SizedBox(width: 10.w), // Tùy chọn nếu bạn muốn có khoảng cách giữa các nút
                            Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _onSignUpStaffClicked();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D80F8),
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
                                      color: Colors.white,
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
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D80F8),
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
                                      color: Colors.white,
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

    var isValidStaff = _authBloc.isValidStaffSignUp(
      _nameStaffController.text,
      _emailStaffController.text,
      _phoneStaffController.text,
      _selectedRole!,
    );

    if (!isValidStaff) return;

    // Hiển thị dialog loading
    LoadingDialog.showLoadingDialog(context, 'Đang tải ...');

    try {
      final imageProvider = Provider.of<UserImageProvider>(context, listen: false);
      final userId = const Uuid().v4(); // Tạm tạo UID (nếu chưa có user thực)

      final imageUrl = await imageProvider.uploadSelectedImageAndGetUrl(userId);

      if (imageUrl == null) {
        LoadingDialog.hideLoadingDialog(context);
        MsgDialog.showMsgDialog(context, "Lỗi", "Bạn chưa chọn ảnh. Vui lòng chọn lại");
        return;
      }

      _imageUrl = imageUrl;

      // Gọi hàm tạo tài khoản
      _authBloc.signUpStaff(
        nameStaff: _nameStaffController.text,
        emailStaff: _emailStaffController.text,
        phoneStaff: _phoneStaffController.text,
        position: _selectedRole!,
        imageUrlStaff: _imageUrl!,
        onSuccess: () {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Tạo tài khoản thành công!", "Tài khoản đã được tạo");
        },
        onRegisterError: (msg) {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Tạo tài khoản thất bại !", msg);
        },
      );
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Lỗi hệ thống", "Không thể tạo tài khoản: $e");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
      child: StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) {
          return TextField(
            controller: controller,
            style: TextStyle(fontSize: 4.sp, color: Colors.black),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 4.sp
              ),
              errorText: snapshot.hasError ? snapshot.error as String : null,
              contentPadding:
              EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xffCED0D2), width: 1.w),
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
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                label+":",
                style: TextStyle(color: Colors.black, fontSize: 4.sp),
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
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 135.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
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

}
