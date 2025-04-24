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
                padding: EdgeInsets.only(left: 80, right: 80, top: 140.h),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bên trái: ảnh
                        Expanded(
                          child:
                          Consumer<UserImageProvider>(
                              builder: (context, avatarProvider, child) {
                                String? avatarUrl = avatarProvider.avatarUrl;
                                return GestureDetector(
                                  onTap: () async {
                                    final provider = Provider.of<UserImageProvider>(context, listen: false);

                                    await provider.pickImage(); // chỉ lưu tạm vào _selectedImageFile

                                    await Future.delayed(Duration(milliseconds: 300));
                                    if (kIsWeb) {
                                      print("🧾 Ảnh web đã chọn: ${provider.webImageBytes != null ? "Đã có dữ liệu bytes" : "null"}");
                                    } else {
                                      print("🧾 Ảnh file đã chọn: ${provider.selectedImageFile?.path ?? "null"}");
                                    }
                                    // Kiểm tra nếu không có ảnh hoặc ảnh không thể tải
                                    if (provider.selectedImageFile == null && provider.webImageBytes == null && avatarUrl == null) {
                                      MsgDialog.showMsgDialog(context, "Lỗi", "Không thể tải được ảnh ");
                                    }
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade200, width: 0.5.w), // Viền xám mỏng
                                        ),
                                        child: CircleAvatar(
                                          radius: 150.r,
                                          backgroundColor: Colors.white,
                                          child: avatarUrl != null
                                              ? ClipOval(
                                            child: Image.network(
                                              '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                              fit: BoxFit.cover,
                                              width: 300.w,
                                              height: 300.h,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                              errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.error, color: Colors.red),
                                            ),
                                          )
                                              : avatarProvider.webImageBytes != null
                                              ? ClipOval(
                                            child: Image.memory(
                                              avatarProvider.webImageBytes!,
                                              fit: BoxFit.cover,
                                              width: 300.w,
                                              height: 300.h,
                                            ),
                                          )
                                              : avatarProvider.selectedImageFile != null
                                              ? ClipOval(
                                            child: Image.file(
                                              avatarProvider.selectedImageFile!,
                                              fit: BoxFit.cover,
                                              width: 300.w,
                                              height: 300.h,
                                            ),
                                          )
                                              : Icon(Icons.add_a_photo, size: 15.sp, color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          padding:  EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.h),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Text(
                                            (avatarUrl != null ||
                                                avatarProvider.selectedImageFile != null ||
                                                avatarProvider.webImageBytes != null)
                                                ? 'Thay đổi'
                                                : 'Thêm ảnh',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 4.sp,
                                            ),
                                          ),

                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                          ),
                        ),
                        // Bên phải: form login
                        Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                ),
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
                                SizedBox(
                                  height: 40.h,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60.h,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _onSignUpStaffClicked();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            const Color(0xFF2D80F8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(30.r),
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
                                    SizedBox(width: 20.w),
                                    // Khoảng cách giữa 2 nút
                                    Expanded(
                                      child: SizedBox(
                                        height: 60.h,
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            const Color(0xFF2D80F8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(30.r),
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
                                  ],
                                ),
                              ],
                            )),
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
        name: _nameStaffController.text,
        email: _emailStaffController.text,
        phone: _phoneStaffController.text,
        position: _selectedRole!,
        imageUrl: _imageUrl!,
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
                width: 172.w,
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
