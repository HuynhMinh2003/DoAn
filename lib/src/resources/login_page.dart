import 'package:do_an/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_framework/responsive_framework.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
        child: Center(
          child: isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  /// Layout cho Desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/images/two_circle.png',
                width: 160,
              )),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              children: [
                // Bên trái: ảnh
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 160),
                      child: SvgPicture.asset(
                        'assets/images/image_login.svg',
                        width: 300,
                      ),
                    ),
                  ),
                ),

                // Bên phải: form login
                Expanded(
                    child: Column(
                  children: [
                    const SizedBox(height: 180),

                    // Tiêu đề
                    Text(
                      'Chào mừng trở lại',
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Đăng nhập để tiếp tục trải nghiệm !',
                      style: TextStyle(
                          fontFamily: "Oswald",
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 24),

                    // Email
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nhập email của bạn',
                        fillColor: Colors.grey[200],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mật khẩu
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu của bạn',
                        fillColor: Colors.grey[200],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nút đăng nhập
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D80F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black45,
                        ),
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(
                              fontFamily: "Oswald",
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          )
        ],
      )),
    );
  }

  /// Layout cho Mobile (giữ nguyên như bạn có)
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 180),

                  // Tiêu đề
                  Text(
                    'Chào mừng trở lại',
                    style: TextStyle(
                      fontFamily: "Oswald",
                      fontWeight: FontWeight.w700,
                      fontSize: 40.sp,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Đăng nhập để tiếp tục trải nghiệm !',
                    style: TextStyle(
                        fontFamily: "Oswald",
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 24),

                  // Hình minh hoạ
                  SvgPicture.asset(
                    'assets/images/image_login.svg',
                    width: 150,
                    height: 150,
                  ),

                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập email của bạn',
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mật khẩu
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu của bạn',
                      fillColor: Colors.grey[200],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nút đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D80F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black45,
                      ),
                      child: const Text(
                        "Đăng nhập",
                        style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email
        TextField(
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Nhập email của bạn',
            fillColor: Colors.grey[200],
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          obscureText: true,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu của bạn',
            fillColor: Colors.grey[200],
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D80F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
              shadowColor: Colors.black45,
            ),
            child: const Text(
              "Đăng nhập",
              style: TextStyle(
                fontFamily: "Oswald",
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
