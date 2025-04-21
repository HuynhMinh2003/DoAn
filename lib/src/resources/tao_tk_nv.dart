import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddAccountStaffPage extends StatefulWidget {
  const AddAccountStaffPage({super.key});

  @override
  State<AddAccountStaffPage> createState() => _AddAccountStaffPageState();
}

class _AddAccountStaffPageState extends State<AddAccountStaffPage> {
  final TextEditingController _nameStaffController = TextEditingController();
  final TextEditingController _emailStaffController = TextEditingController();
  final TextEditingController _phoneStaffController = TextEditingController();
  final TextEditingController _rollStaffController = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  @override
  void dispose() {
    _nameStaffController.dispose();
    _emailStaffController.dispose();
    _phoneStaffController.dispose();
    _rollStaffController.dispose();
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
                                SizedBox(
                                  height: 10.h,
                                ),
                                _buildTextField(
                                  controller: _nameStaffController,
                                  label: 'Họ và tên:',
                                  stream: _authBloc.nameStaffStream,
                                ),
                                _buildTextField(
                                  controller: _emailStaffController,
                                  label: 'Số điện thoại:',
                                  stream: _authBloc.emailStaffStream,
                                ),
                                _buildTextField(
                                  controller: _phoneStaffController,
                                  label: 'Email:',
                                  stream: _authBloc.phoneStaffStream,
                                ),
                                _buildTextField(
                                  controller: _rollStaffController,
                                  label: 'Vai trò:',
                                  stream: _authBloc.rollStaffStream,
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

}

class FilterDropdown extends StatefulWidget {
  final String label;

  const FilterDropdown({super.key, required this.label});

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // đừng quên xoá controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.only(bottom: isLandscape ? 50.h : 50.h),
      //  padding thay đổi theo màn hình
      child: Row(
        children: [
          SizedBox(
            width: isLandscape ? 50.w : 100.w,
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: "Oswald",
                fontWeight: FontWeight.w700,
                fontSize: isLandscape ? 8.sp : 16.sp,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Container(
              height: 30.h,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black26),
                ),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  // có thể trigger search logic hoặc UI cập nhật ở đây
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
