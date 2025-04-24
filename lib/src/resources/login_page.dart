import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/quan_li_mobile.dart';
import 'package:do_an/src/resources/quan_li_web.dart';
import 'package:do_an/src/resources/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCompanyController1 =
      TextEditingController();
  final TextEditingController _passCompanyController1 = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  bool _isPressed1 = false;

  // Hàm lưu token FCM vào Firestore (tránh lưu trùng)
  Future<void> _saveTokenToFirestore(String newToken) async {
    final staffId = FirebaseAuth.instance.currentUser?.uid;
    if (staffId == null) return; // Không có userId thì thoát luôn

    try {
      // Đường dẫn Firestore cho nhân viên
      DocumentReference staffRef =
          FirebaseFirestore.instance.collection("users").doc(staffId);
      DocumentSnapshot staffDoc = await staffRef.get();

      if (staffDoc.exists) {
        // Lấy danh sách token hiện tại
        List<String> tokens = List<String>.from(staffDoc['fcmTokens'] ?? []);

        if (!tokens.contains(newToken)) {
          // Nếu token chưa tồn tại thì thêm vào danh sách
          await staffRef.update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Nếu tài liệu của nhân viên chưa tồn tại, tạo mới với danh sách token
        await staffRef.set({
          'fcmTokens': [newToken],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      print("FCM Token saved successfully!");
    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

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

    return GestureDetector(
        onTap: () {
          // Ẩn bàn phím khi chạm ra ngoài TextField
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
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
                  padding: EdgeInsets.only(
                      left: isLandscape ? 80 : 24.w,
                      right: isLandscape ? 80 : 24.w,
                      top: 170.h),
                  child: isLandscape
                      ? _buildLandScapeLayout(context)
                      : _buildPortraitLayout(context),
                ),
              ],
            ),
          ),
        ));
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

                _buildTextField(
                    controller: _emailCompanyController1,
                    label: "Nhập email",
                    stream: _authBloc.emailStream),

                _buildTextField(
                    controller: _passCompanyController1,
                    label: "Nhập password",
                    stream: _authBloc.passStream),

                SizedBox(height: 10.h),

                Align(
                  alignment: Alignment.centerRight,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return GestureDetector(
                          onTapDown: (_) => setState(() => _isPressed1 = true),
                          onTapCancel: () =>
                              setState(() => _isPressed1 = false),
                          onTapUp: (_) {
                            setState(() => _isPressed1 = false);
                            _onForgotPasswordClick();
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
                    onPressed: () {
                      _onLoginClick();
                    },
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

        _buildTextField(
            controller: _emailCompanyController1,
            label: "Nhập email",
            stream: _authBloc.emailStream),

        _buildTextField(
            controller: _passCompanyController1,
            label: "Nhập password",
            stream: _authBloc.passStream),

        SizedBox(height: 10.h),

        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed1 = true),
                  onTapCancel: () => setState(() => _isPressed1 = false),
                  onTapUp: (_) {
                    setState(() => _isPressed1 = false);
                    _onForgotPasswordClick();
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
            onPressed: () {
              _onLoginClick();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D80F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
              shadowColor: Colors.black45,
              alignment: Alignment.center,
              // đảm bảo text ở giữa
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

  _onForgotPasswordClick() {
    TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h, // Đẩy nội dung lên khi bàn phím mở
            top: 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Quên mật khẩu",
                style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 10.h),
              const Text("Vui lòng nhập email của bạn để tiếp tục"),
              SizedBox(height: 10.h),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Nhập địa chỉ email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Đóng bottom sheet
                    child: const Text("Hủy"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String email = emailController.text.trim();
                      if (email.isEmpty) {
                        _showCustomSnackBar(context, "Nhập địa chỉ email", Colors.red, Icons.error);
                        return;
                      }

                      // Hiển thị dialog loading
                      LoadingDialog.showLoadingDialog(context, "Kiểm tra tài khoản...");

                      try {
                        // Lấy email từ Firestore
                        var userRef = FirebaseFirestore.instance.collection('staffs').where('email', isEqualTo: email);
                        var querySnapshot = await userRef.get();

                        // Kiểm tra nếu email tồn tại trong Firestore
                        if (querySnapshot.docs.isEmpty) {
                          Navigator.pop(context); // Đóng loading dialog và bottom sheet
                          Future.delayed(Duration(milliseconds: 200), () {
                            _showCustomSnackBar(context, "Email này không tồn tại trong hệ thống", Colors.red, Icons.error);
                          });
                          return;
                        } else {
                          // Gửi email reset mật khẩu nếu tất cả điều kiện đã thông qua
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          Navigator.pop(context); // Đóng loading dialog và bottom sheet
                          Future.delayed(Duration(milliseconds: 200), () {
                            _showCustomSnackBar(context, "Link đặt lại mật khẩu đã được gửi!", Colors.green, Icons.check_circle);
                          });
                        }
                      } catch (error) {
                        Navigator.pop(context); // Đóng loading dialog và bottom sheet
                        Future.delayed(Duration(milliseconds: 200), () {
                          _showCustomSnackBar(context, error.toString(), Colors.red, Icons.error);
                        });
                      }
                    },
                    child: const Text("Gửi"),
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
  void _showCustomSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // Hiển thị nổi lên thay vì dính dưới cùng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Bo góc SnackBar
        ),
        margin: EdgeInsets.all(10), // Tạo khoảng cách xung quanh
        duration: Duration(seconds: 3), // Hiển thị trong 3 giây
      ),
    );
  }


  _onLoginClick() {
    String email = _emailCompanyController1.text;
    String pass = _passCompanyController1.text;

    var isValid = _authBloc.isValidSignIn(email, pass);

    if (isValid) {
      LoadingDialog.showLoadingDialog(context, "Đang tải ...");

      _authBloc.signIn(
        email: email,
        pass: pass,
        onSuccess: () async {
          LoadingDialog.hideLoadingDialog(context);

          // Lấy UID của người dùng đã đăng nhập
          var currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            String userId = currentUser.uid;

            // Cập nhật FCM token sau khi đăng nhập
            String? newToken = await FirebaseMessaging.instance.getToken();

            // Lấy thông tin từ Firestore
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection("staffs")
                .doc(userId)
                .get();

            if (userDoc.exists) {
              // Lấy role từ Firestore
              int role = userDoc.get('role');

              // Kiểm tra thiết bị (mobile/web)
              bool isMobile = !kIsWeb;

              // Điều hướng theo role và thiết bị
              if (role == 1) {
                if (isMobile) {
                  // Trên thiết bị mobile -> Giao diện 1
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const AdminMobilePage(),
                  ));
                  if (newToken != null) {
                    await _saveTokenToFirestore(
                        newToken); // Gọi hàm lưu token vào Firestore
                  }
                } else {
                  // Trên web -> Giao diện 2
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const AdminWebPage(),
                  ));
                  if (newToken != null) {
                    await _saveTokenToFirestore(
                        newToken); // Gọi hàm lưu token vào Firestore
                  }
                }
              } else if (role == 2 || role == 3 || role == 4) {
                if (isMobile) {
                  // Trên mobile -> Điều hướng đến giao diện tương ứng
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const TestPage(),
                  ));
                  if (newToken != null) {
                    await _saveTokenToFirestore(
                        newToken); // Gọi hàm lưu token vào Firestore
                  }
                } else {
                  // Trên web -> Hiển thị thông báo
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                }
              }
            }
          } else {
            MsgDialog.showMsgDialog(
                context, "Lỗi", "Xác thực người dùng không thành công");
          }
        },
        onSignInError: (msg) {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Đăng nhập", msg);
        },
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Builder(builder: (context){
      final size = MediaQuery.of(context).size;
      final isLandscape = size.height < size.width;
      return Padding(
        padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
        child: StreamBuilder<String>(
          stream: stream,
          builder: (context, snapshot) {
            return TextField(
              controller: controller,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                labelText: label,
                errorText: snapshot.hasError ? snapshot.error as String : null,
                contentPadding:
                EdgeInsets.symmetric(vertical: 2.h, horizontal: isLandscape? 8.w:24.w),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xffCED0D2), width: 1.w),
                  borderRadius: BorderRadius.all(Radius.circular(30.r)),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
