import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPressed1 = false;

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
              padding: EdgeInsets.symmetric(horizontal: isLandscape  ? 80 : 24.w ),
              child: isLandscape  ? _buildDesktopLayout(context):_buildMobileLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout cho Desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Bên trái: ảnh
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: 200.h),
              child: SvgPicture.asset(
                'assets/images/image_login.svg',
                width: 300.h,
              ),
            ),
          ),
        ),

        // Bên phải: form login
        Expanded(
            child: Column(
              children: [
                SizedBox(height: 200.h),
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

                SizedBox(height: 24.h),

                // Email
                TextField(
                  style: TextStyle( // 👈 đây là font của text người dùng nhập
                    fontSize: 4.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập email của bạn',
                    hintStyle: TextStyle( // 👈 đây là font của hint
                      fontSize: 4.sp,
                      color: Colors.grey,
                    ),
                    fillColor: Colors.grey[200],
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 14.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Mật khẩu
                TextField(
                  obscureText: true,
                  style: TextStyle( // 👈 đây là font của text người dùng nhập
                    fontSize: 4.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu của bạn',
                    hintStyle: TextStyle( // 👈 đây là font của hint
                      fontSize: 4.sp,
                      color: Colors.grey,
                    ),
                    fillColor: Colors.grey[200],
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 14.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),


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
    );
  }

  /// Layout cho Mobile (giữ nguyên như bạn có)
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 180.h),

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

        // Email
        TextField(
          style: TextStyle( // 👈 đây là font của text người dùng nhập
            fontSize: 15.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập email của bạn',
            hintStyle: TextStyle( // 👈 đây là font của hint
              fontSize: 15.sp,
              color: Colors.grey,
            ),
            fillColor: Colors.grey[200],
            filled: true,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Mật khẩu
        TextField(
          obscureText: true,
          style: TextStyle( // 👈 đây là font của text người dùng nhập
            fontSize: 15.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu của bạn',
            hintStyle: TextStyle( // 👈 đây là font của hint
              fontSize: 15.sp,
              color: Colors.grey,
            ),
            fillColor: Colors.grey[200],
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),

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
}

