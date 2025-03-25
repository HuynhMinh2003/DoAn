import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/admin_page.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/home_page.dart';
import 'package:do_an/src/resources/waiting_page.dart';
import 'package:do_an/src/resources/register_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthBloc authBloc = AuthBloc();

  final TextEditingController _emailController1 = TextEditingController();
  final TextEditingController _passController1 = TextEditingController();
  bool _isObscure = true; // Biến trạng thái để kiểm soát hiển thị mật khẩu
  bool isPressed = false;
  bool _isPressed = false;
  bool _isPressed1 = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Làm trong suốt
        statusBarIconBrightness: Brightness.light, // Icon màu trắng
      ),
    );
    print("Login Screen INIT");
  }

  @override
  void dispose() {
    print("Login Screen DISPOSED");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("📌 Login Screen rebuilt");

    return LayoutBuilder(builder: (context, constraints){
      return Scaffold(
        resizeToAvoidBottomInset: false,
        // Cho phép đẩy nội dung khi bàn phím xuất hiện
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Stack(
            children: [
              // Ảnh nền
              Positioned.fill(
                child: Image.asset(
                  'assets/ic_login.png',
                  fit: BoxFit.cover, // Đảm bảo ảnh nền phủ toàn bộ màn hình
                ),
              ),

              SafeArea(child: KeyboardVisibilityBuilder(
                  builder: (context, isKeyboardVisible) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 100.h,
                      ),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height -
                                MediaQuery.of(context)
                                    .padding
                                    .top, // Giới hạn đúng chiều cao
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: Offset(-10.5.w, -110.h),
                                // Đẩy ảnh lên 20 pixels
                                child: Transform.scale(
                                  scale: 3.5, // Phóng to ảnh
                                  child: Image.asset(
                                    'assets/ic_hinhtron.png',
                                    width: 0.55.sw,
                                    // Chiều rộng dựa trên kích thước màn hình
                                    height: 0.2.sh,
                                    // Chiều cao dựa trên kích thước màn hình
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 40.h, horizontal: 30.w),
                                // Chỉ padding ngang
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Chào mừng
                                    Padding(
                                      padding:
                                      EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 1.h),
                                      child: Text(
                                        'Welcome back!',
                                        style: GoogleFonts.pacifico(
                                          fontSize: 45,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding:
                                      EdgeInsets.fromLTRB(0.w, 5.h, 0.w, 0.h),
                                      child: Text(
                                        'Login to continue using hApp',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    ),

                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 0.h),
                                      child: StreamBuilder<String>(
                                        stream: authBloc.emailStream1,
                                        builder: (context, snapshot) => Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: _inputBoxDecoration(),
                                              child: TextField(
                                                controller: _emailController1,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                                keyboardType:
                                                TextInputType.emailAddress,
                                                decoration: _inputDecoration(
                                                  'Email',
                                                  const Icon(Icons.email,
                                                      color: Colors.blue),
                                                  Colors.grey,
                                                ),
                                              ),
                                            ),
                                            // Hiển thị lỗi bên dưới TextField
                                            if (snapshot.hasError)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5.h, left: 8.w),
                                                child: Text(
                                                  snapshot.error.toString(),
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding:
                                      EdgeInsets.fromLTRB(0.w, 20.h, 0.w, 5.h),
                                      child: StreamBuilder<String>(
                                        stream: authBloc.passStream1,
                                        builder: (context, snapshot) => Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: _inputBoxDecoration(),
                                              child: StatefulBuilder(
                                                builder: (context, setState) {
                                                  return TextField(
                                                    controller: _passController1,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                    obscureText: _isObscure,
                                                    decoration: _inputDecoration1(
                                                      'Password',
                                                      const Icon(Icons.lock,
                                                          color: Colors.blue),
                                                      Colors.grey,
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _isObscure
                                                              ? Icons.visibility
                                                              : Icons
                                                              .visibility_off,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _isObscure =
                                                            !_isObscure;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // Hiển thị lỗi bên dưới TextField
                                            if (snapshot.hasError)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5.h, left: 8.w),
                                                child: Text(
                                                  snapshot.error.toString(),
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: StatefulBuilder(
                                          builder: (context, setState) {
                                            return GestureDetector(
                                              onTapDown: (_) => setState(
                                                      () => _isPressed1 = true),
                                              onTapCancel: () => setState(
                                                      () => _isPressed1 = false),
                                              onTapUp: (_) {
                                                setState(() => _isPressed1 = false);
                                                _onForgotPasswordClick();
                                              },
                                              child: Text(
                                                'Forgot password?',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xfff9fafc)
                                                      .withOpacity(_isPressed1
                                                      ? 0.6
                                                      : 1.0), // Hiệu ứng nhấn
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Nút Login
                                    Padding(
                                      padding:
                                      EdgeInsets.fromLTRB(0.w, 75.h, 0.w, 10.h),
                                      child: GestureDetector(
                                        onTap: _onLoginClick,
                                        onTapDown: (_) =>
                                            setState(() => isPressed = true),
                                        // Khi nhấn xuống
                                        onTapUp: (_) =>
                                            setState(() => isPressed = false),
                                        // Khi thả ra
                                        onTapCancel: () =>
                                            setState(() => isPressed = false),
                                        // Khi hủy nhấn
                                        child: AnimatedContainer(
                                          duration:
                                          const Duration(milliseconds: 100),
                                          width: double.infinity,
                                          height: 52.h,
                                          transform: isPressed
                                              ? Matrix4.translationValues(
                                              2.w, 2.h, 0)
                                              : Matrix4.identity(),
                                          // Hiệu ứng lún xuống
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(30.r),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF0D1F41),
                                                Color(0xFF2054B0),
                                                // Màu xanh chính
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: isPressed
                                                ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                // Bóng mờ hơn khi nhấn
                                                offset: Offset(2.w, 2.h),
                                                blurRadius: 3.r,
                                              ),
                                            ]
                                                : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    0.4), // Bóng đậm phía dưới
                                                offset: Offset(4.w, 4.h),
                                                blurRadius: 5.r,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            0.w, 20.h, 0.w, 30.h),
                                        child: RichText(
                                          text: TextSpan(
                                            text: 'New user? ',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                            children: [
                                              TextSpan(
                                                text: "Sign up for a new account",
                                                style: TextStyle(
                                                  color: Colors.blue.withOpacity(
                                                      _isPressed ? 0.6 : 1.0),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                  TextDecoration.underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTapDown = (_) {
                                                    setState(() {
                                                      _isPressed = true;
                                                    });
                                                  }
                                                  ..onTapUp = (_) {
                                                    setState(() {
                                                      _isPressed = false;
                                                    });

                                                    Navigator.of(context)
                                                        .push(PageRouteBuilder(
                                                      transitionDuration: Duration(
                                                          milliseconds: 1000),
                                                      // Thời gian hiệu ứng
                                                      pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                          RegisterPage(),
                                                      transitionsBuilder: (context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child) {
                                                        var fadeAnimation =
                                                        Tween<double>(
                                                          begin: 0.0,
                                                          // Bắt đầu từ trong suốt
                                                          end:
                                                          1.0, // Hiện ra hoàn toàn
                                                        ).animate(animation);

                                                        var scaleAnimation =
                                                        Tween<double>(
                                                          begin: 0.8,
                                                          // Nhỏ hơn bình thường
                                                          end:
                                                          1.0, // Phóng to đến kích thước chuẩn
                                                        ).animate(animation);

                                                        return FadeTransition(
                                                          opacity: fadeAnimation,
                                                          child: ScaleTransition(
                                                            scale: scaleAnimation,
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                    ));
                                                  }
                                                  ..onTapCancel = () {
                                                    setState(() {
                                                      _isPressed = false;
                                                    });
                                                  },
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    );
                  })),
            ],
          ),
        ));});
  }

  void _onForgotPasswordClick() {
    TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                20.h, // Đẩy nội dung lên khi bàn phím mở
            top: 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Forgot Password",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text("Please enter your email to reset your password."),
              SizedBox(height: 10.h),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    // Đóng bottom sheet
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      String email = emailController.text.trim();
                      if (email.isEmpty) {
                        _showCustomSnackBar(context, "Please enter your email.",
                            Colors.red, Icons.error);
                        return;
                      }

                      FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email)
                          .then((value) {
                        Navigator.pop(
                            context); // Đóng bottom sheet sau khi gửi email
                        _showCustomSnackBar(
                            context,
                            "Password reset link sent!",
                            Colors.green,
                            Icons.check_circle);
                      }).catchError((error) {
                        _showCustomSnackBar(
                            context, error.toString(), Colors.red, Icons.error);
                      });
                    },
                    child: Text("Send"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

// Hàm hiển thị SnackBar đẹp hơn
  void _showCustomSnackBar(
      BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10.w),
            Expanded(
                child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        // Hiển thị nổi lên thay vì dính dưới cùng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Bo góc SnackBar
        ),
        margin: EdgeInsets.all(20.r),
        // Tạo khoảng cách xung quanh
        duration: Duration(seconds: 3), // Hiển thị trong 3 giây
      ),
    );
  }

  void _onLoginClick() {
    String email = _emailController1.text;
    String pass = _passController1.text;

    var isValid1 = authBloc.isValidSignIn(email, pass);

    if (isValid1) {
      LoadingDialog.showLoadingDialog(context, "Loading...");

      authBloc.signIn(
        email: email,
        pass: pass,
        onSuccess: () async {
          LoadingDialog.hideLoadingDialog(context);

          // Kiểm tra nếu email là 'hmvn2003@gmail.com'
          if (email == 'hmvn2003@gmail.com') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ));
            return;
          }

          // Lấy UID của người dùng đã đăng nhập
          var currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            String userId = currentUser.uid;

            // Lấy thông tin từ Realtime Database
            DatabaseReference userRef =
                FirebaseDatabase.instance.ref('users/$userId');
            DatabaseEvent event = await userRef.once();

            if (event.snapshot.exists) {
              bool isApproved =
                  event.snapshot.child('isApproved').value as bool;

              if (isApproved) {
                // Lấy thông tin user từ Firebase hoặc SharedPreferences
                Map<String, dynamic> userData = {
                  'uid': FirebaseAuth.instance.currentUser?.uid ?? '',
                  'name':
                      FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                  'email':
                      FirebaseAuth.instance.currentUser?.email ?? 'No email',
                };

                // Nếu isApproved là true, điều hướng đến HomePage và truyền userData
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomePage(userData: userData),
                ));
              } else {
                // Nếu isApproved là false, điều hướng đến WaitingPage
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WaitingForApprovalPage(),
                  ),
                );

              }
            } else {
              MsgDialog.showMsgDialog(context, "Error",
                  "Tên người dùng không được tìm thấy trong dữ liệu.\nTài khoản có thể đã bị xóa hoặc không được duyệt.");
            }
          } else {
            MsgDialog.showMsgDialog(
                context, "Error", "User authentication failed.");
          }
        },
        onSignInError: (msg) {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Sign in", msg);
        },
      );
    }
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF2C5364),
          Color(0xFF203A43),
          Color(0xFF12232A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6.r,
          offset: Offset(0.w, 3.h),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, Icon icon, Color labelColor) {
    return InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: labelColor, fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.transparent,
      prefixIcon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: icon,
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide.none, // Loại bỏ viền để hợp với gradient
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
            color: Colors.white, width: 1.5), // Viền trắng khi focus
      ),
    );
  }

  InputDecoration _inputDecoration1(String hint, Icon icon, Color labelColor,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: labelColor, fontSize: 14),
      // Label màu trắng để dễ nhìn
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.transparent,
      // Nền trong suốt để hiện gradient
      prefixIcon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: icon,
      ),
      suffixIcon: suffixIcon,
      // Thêm icon đuôi nếu cần
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1), // Viền mờ khi chưa focus
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
            color: Colors.white, width: 1.5), // Viền trắng khi focus
      ),
    );
  }
}
