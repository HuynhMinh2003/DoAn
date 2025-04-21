import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCompanyController1 = TextEditingController();
  final TextEditingController _passCompanyController1 = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  bool _isPressed1 = false;

  @override
  void dispose() {
    _emailCompanyController1.dispose();
    _passCompanyController1.dispose();
    _authBloc.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
        bottom: true, // bảo vệ khỏi thanh đh
        top: true, // bảo vệ khỏi thanh tb
        child: Stack(
          children: [
            // Ảnh hình tròn trang trí (top left)
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/images/two_circle.png',
                width: 160,
              ),
            ),

            // Nội dung chính
            SingleChildScrollView(
              padding: EdgeInsets.only(left: isLandscape  ? 80: 24.w, right: isLandscape  ? 80: 24.w, top: 170.h),
              child: isLandscape  ? _buildLandScapeLayout(context):_buildPortraitLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout cho Desktop
  Widget _buildLandScapeLayout(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bên trái: ảnh
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 30.w),
                  child: SvgPicture.asset(
                    'assets/images/image_login.svg',
                    width: 400.h,
                  ),
                ),
              ),
            ),

            // Bên phải: form login
            Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 50.h),
                    // Tiêu đề
                    Text(
                      'Chào mừng trở lại',
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Đăng nhập để tiếp tục trải nghiệm !',
                      style: TextStyle(
                          fontFamily: "Oswald",
                          fontSize: 5.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 30.h),

                    _buildTextField(controller: _emailCompanyController1, label: "Nhập email" , stream: _authBloc.emailStream),

                    _buildTextField(controller: _passCompanyController1, label: "Nhập password" , stream: _authBloc.passStream),


                    SizedBox(height: 10.h),

                    Align(
                      alignment: Alignment.centerRight,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _isPressed1 = true),
                              onTapCancel: () =>
                                  setState(() => _isPressed1 = false),
                              onTapUp: (_) {
                                setState(() => _isPressed1 = false);
                                // _onForgotPasswordClick();
                              },
                              child: Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  fontSize: 4.sp,
                                  color: const Color(0xFF0077BE).withOpacity(
                                      _isPressed1 ? 0.6 : 1.0), // Hiệu ứng nhấn
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Nút đăng nhập
                    SizedBox(
                      width: double.infinity,
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
                        ),
                        child: Text(
                          "Đăng nhập",
                          style: TextStyle(
                              fontFamily: "Oswald",
                              fontWeight: FontWeight.w700,
                              fontSize: 8.sp,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  /// Layout cho Mobile
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tiêu đề
        Text(
          'Chào mừng trở lại',
          style: TextStyle(
            fontFamily: "Oswald",
            fontWeight: FontWeight.w700,
            fontSize: 40.sp,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'Đăng nhập để tiếp tục trải nghiệm !',
          style: TextStyle(
              fontFamily: "Oswald",
              fontSize: 14.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 24.h),

        // Hình minh hoạ
        SvgPicture.asset(
          'assets/images/image_login.svg',
          width: 150.w,
          height: 150.h,
        ),

        SizedBox(height: 24.h),

        _buildTextField(controller: _emailCompanyController1, label: "Nhập email" , stream: _authBloc.emailStream),

        _buildTextField(controller: _passCompanyController1, label: "Nhập password" , stream: _authBloc.passStream),

        SizedBox(height: 10.h),

        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) =>
                      setState(() => _isPressed1 = true),
                  onTapCancel: () =>
                      setState(() => _isPressed1 = false),
                  onTapUp: (_) {
                    setState(() => _isPressed1 = false);
                    // _onForgotPasswordClick();
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF0077BE).withOpacity(
                          _isPressed1 ? 0.6 : 1.0), // Hiệu ứng nhấn
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(height: 50.h),

        // Nút đăng nhập
        SizedBox(
          width: double.infinity,
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
              alignment: Alignment.center, // đảm bảo text ở giữa
              padding: EdgeInsets.zero, // tránh padding dư thừa không cần thiết
            ),
            child: Text(
              "Đăng nhập",
              style: TextStyle(
                fontFamily: "Oswald",
                fontWeight: FontWeight.w700,
                fontSize: 25.sp,
                color: Colors.white,
                height: 1.0, // giúp canh chỉnh theo baseline tốt hơn
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

      ],
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

