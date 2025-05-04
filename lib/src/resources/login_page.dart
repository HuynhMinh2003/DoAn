import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/staff_page.dart';
import 'package:do_an/src/resources/quan_li_web.dart';
import 'package:do_an/src/resources/home_first_staff_page.dart';
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
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  bool _isPressed1 = false;

// Hàm lưu token FCM vào Firestore (tránh lưu trùng)
  Future<void> _saveTokenToFirestore(String newToken) async {
    final staffId = FirebaseAuth.instance.currentUser?.uid;
    if (staffId == null) return; // Không có userId thì thoát luôn

    try {
      // Đường dẫn Firestore cho nhân viên
      DocumentReference staffRef =
      FirebaseFirestore.instance.collection("staffs").doc(staffId);
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
          'fcmTokens': [newToken],  // Lưu mảng token FCM
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print("FCM Token saved successfully!");
    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

  Future<void> _saveResidentTokenToFirestore(String newToken) async {
    final residentId = FirebaseAuth.instance.currentUser?.uid;
    if (residentId == null) return; // Không có userId thì thoát luôn

    try {
      // Đường dẫn Firestore cho nhân viên
      DocumentReference residentRef =
      FirebaseFirestore.instance.collection("residents").doc(residentId);
      DocumentSnapshot residentDoc = await residentRef.get();

      if (residentDoc.exists) {
        // Lấy danh sách token hiện tại
        List<String> tokens = List<String>.from(residentDoc['fcmTokens'] ?? []);

        if (!tokens.contains(newToken)) {
          // Nếu token chưa tồn tại thì thêm vào danh sách
          await residentRef.update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Nếu tài liệu của nhân viên chưa tồn tại, tạo mới với danh sách token
        await residentRef.set({
          'fcmTokens': [newToken],  // Lưu mảng token FCM
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
    _emailController.dispose();
    _passController.dispose();
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
                    controller: _emailController,
                    label: "Nhập email",
                    stream: _authBloc.emailStream),

                _buildTextField(
                    controller: _passController,
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

                SizedBox(height: 40.h),

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
              fontSize: 16.sp,
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
            controller: _emailController,
            label: "Nhập email",
            stream: _authBloc.emailStream),

        _buildTextField(
            controller: _passController,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final isLandscape = size.height < size.width;

        return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  20.h, // Đẩy nội dung lên khi bàn phím mở
              top: 20.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Quên mật khẩu",
                    style: TextStyle(
                      fontFamily: "Oswald",
                      fontWeight: FontWeight.w700,
                      fontSize: isLandscape ? 6.sp : 20.sp,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    "Vui lòng nhập email của bạn để tiếp tục",
                    style: TextStyle(
                      fontSize: isLandscape ? 5.sp : 16.sp,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Nhập địa chỉ email",
                      hintStyle:
                          TextStyle(fontSize: isLandscape ? 6.sp : 14.sp),
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
                        child: Text(
                          "Hủy",
                          style:
                              TextStyle(fontSize: isLandscape ? 5.sp : 14.sp),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          String email = emailController.text.trim();
                          if (email.isEmpty) {
                            _showCustomSnackBar(context, "Vui lòng nhập địa chỉ email !",
                                Colors.red, Icons.error);
                            return;
                          }

                          // Hiển thị dialog loading
                          LoadingDialog.showLoadingDialog(
                              context, "Kiểm tra tài khoản...");

                          try {
                            // Lấy email từ Firestore
                            var userRef = FirebaseFirestore.instance
                                .collection('staffs')
                                .where('email', isEqualTo: email);
                            var querySnapshot = await userRef.get();

                            if (!mounted) return; // đảm bảo context còn sống

                            Navigator.pop(context);

                            // Kiểm tra nếu email tồn tại trong Firestore
                            if (querySnapshot.docs.isEmpty) {
                              Future.delayed(Duration(milliseconds: 200), () {
                                _showCustomSnackBar(
                                    context,
                                    "Email này không tồn tại trong hệ thống",
                                    Colors.red,
                                    Icons.error);
                              });
                              return;
                            } else {
                              // Gửi email reset mật khẩu nếu tất cả điều kiện đã thông qua
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email);
                              Future.delayed(Duration(milliseconds: 200), () {
                                _showCustomSnackBar(
                                    context,
                                    "Link đặt lại mật khẩu đã được gửi!",
                                    Colors.green,
                                    Icons.check_circle);
                              });
                              Navigator.pop(context);

                            }
                          } catch (error) {
                            if(mounted){
                              Navigator.pop(context);
                              Future.delayed(Duration(milliseconds: 200), () {
                                _showCustomSnackBar(context, error.toString(),
                                    Colors.red, Icons.error);
                              });
                            }
                          }
                        },
                        child: Text("Gửi",
                            style: TextStyle(
                                fontSize: isLandscape ? 5.sp : 14.sp)),
                      ),
                    ],
                  ),
                ],
              ),
            ));
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
            SizedBox(width: 10),
            Expanded(
                child: Text(message, style: TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        // Hiển thị nổi lên thay vì dính dưới cùng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r), // Bo góc SnackBar
        ),
        margin: EdgeInsets.all(10),
        // Tạo khoảng cách xung quanh
        duration: Duration(seconds: 3), // Hiển thị trong 3 giây
      ),
    );
  }

  _onLoginClick() async {
// Ẩn bàn phím và remove focus
    FocusScope.of(context).requestFocus(FocusNode());

    // Chờ 100-200ms cho keyboard kịp đóng hoàn toàn
    await Future.delayed(Duration(milliseconds: 150));
    String email = _emailController.text;
    String pass = _passController.text;

    var isValid = _authBloc.isValidSignIn(email, pass);

    if (isValid) {
      LoadingDialog.showLoadingDialog(context, "Đang tải ...");

      _authBloc.signIn(
        email: email,
        pass: pass,
          onSuccess: () async {
            LoadingDialog.hideLoadingDialog(context);

            var currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              String userId = currentUser.uid;

              // Lấy FCM token mới
              String? newToken = await FirebaseMessaging.instance.getToken();

              int? role; // Biến để lưu role

              DocumentSnapshot staffDoc = await FirebaseFirestore.instance
                  .collection("staffs")
                  .doc(userId)
                  .get();

              if (staffDoc.exists && staffDoc.data() != null) {
                role = staffDoc.get('role');
              } else {
                DocumentSnapshot residentDoc = await FirebaseFirestore.instance
                    .collection("residents")
                    .doc(userId)
                    .get();

                if (residentDoc.exists && residentDoc.data() != null) {
                  role = residentDoc.get('role');
                }
              }


              if (role != null) {
                bool isMobile = !kIsWeb;

                if (role == 1) {
                  if (isMobile) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => StaffPage()),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const AdminWebPage()),
                    );
                  }
                } else if (role == 2) {
                  // if (isMobile) {
                  //   Navigator.of(context).pushReplacement(
                  //     MaterialPageRoute(builder: (context) => HomeFirstStaffPage()),
                  //   );
                  //   // Lưu FCM token nếu có
                  //   if (newToken != null) {
                  //     await _saveTokenToFirestore(newToken);
                  //   }
                  // } else {
                  //   MsgDialog.showMsgDialog(
                  //     context,
                  //     "Thông báo",
                  //     "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  //   );
                  // }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeFirstStaffPage()),
                  );
                  // Lưu FCM token nếu có
                  if (newToken != null) {
                    await _saveTokenToFirestore(newToken);
                  }
                } else if (role == 3) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => TestPage()),
                  );
                  // Lưu FCM token nếu có
                  if (newToken != null) {
                    await _saveResidentTokenToFirestore(newToken);
                  }
                }
              } else {
                MsgDialog.showMsgDialog(context, "Lỗi", "Không tìm thấy role cho tài khoản này");
              }
            } else {
              MsgDialog.showMsgDialog(context, "Lỗi", "Xác thực người dùng không thành công");
            }
          },
        onSignInError: (msg) {
          LoadingDialog.hideLoadingDialog(context);
          MsgDialog.showMsgDialog(context, "Đăng nhập", "msg");
        },
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Builder(builder: (context) {
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
                labelStyle: TextStyle(fontSize: isLandscape ? 4.sp : 15.sp),
                errorText: snapshot.hasError ? snapshot.error as String : null,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 2.h, horizontal: isLandscape ? 8.w : 24.w),
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
