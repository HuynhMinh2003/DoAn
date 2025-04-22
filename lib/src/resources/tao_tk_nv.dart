import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';

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
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(right: 30.w),
                              child: SvgPicture.asset(
                                'assets/images/image_signup_nv.svg',
                                width: 600.h,
                              ),
                            ),
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
                                              fontSize: 5.sp,
                                              color: Colors.white,
                                              height: 1.0,
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
                                              fontSize: 5.sp,
                                              color: Colors.white,
                                              height: 1.0,
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
            style: TextStyle(fontSize: 18, color: Colors.black),
            decoration: InputDecoration(
              labelText: label,
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
                style: TextStyle(color: Colors.black),
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

  _onSignUpStaffClicked(){
    if (_selectedRole == null) {
      MsgDialog.showMsgDialog(context, "Lỗi", "Vui lòng chọn vai trò.");
      return;
    }
    var isValidStaff = _authBloc.isValidStaffSignUp(
      _nameStaffController.text,
      _emailStaffController.text,
      _phoneStaffController.text,
      _selectedRole!,
    );

    if (isValidStaff) {
      // loading dialog
      LoadingDialog.showLoadingDialog(context, 'Đang tải ...');

      // create user
      _authBloc.signUpStaff(
        name: _nameStaffController.text,
        email: _emailStaffController.text,
        phone: _phoneStaffController.text,
        position: _selectedRole!,
        onSuccess: () {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Tạo tài khoản thành công!", "Tài khoản đã được tạo.");
        },
        onRegisterError: (msg) {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Tạo tài khoản thất bại !", msg);
        },
      );
    }
  }
}
