import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/screens/main/main_screen.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/home_first_csn_page.dart';
import 'package:do_an/src/resources/home_first_resident_page.dart';
import 'package:do_an/src/resources/home_first_ktv_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'home_first_company_page.dart';

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

  Future<void> _saveTokenAdminToFirestore(String newToken) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) return; // Không có userId thì thoát luôn

    try {
      // Đường dẫn Firestore cho nhân viên
      DocumentReference adminRef =
      FirebaseFirestore.instance.collection("admins").doc(adminId);
      DocumentSnapshot adminDoc = await adminRef.get();

      if (adminDoc.exists) {
        // Lấy danh sách token hiện tại
        List<String> tokens = List<String>.from(adminDoc['fcmTokens'] ?? []);

        if (!tokens.contains(newToken)) {
          // Nếu token chưa tồn tại thì thêm vào danh sách
          await adminRef.update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Nếu tài liệu của nhân viên chưa tồn tại, tạo mới với danh sách token
        await adminRef.set({
          'fcmTokens': [newToken],  // Lưu mảng token FCM
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print("FCM Token saved successfully!");
    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

  Future<void> _saveTokenCompanyToFirestore(String newToken) async {
    final companyId = FirebaseAuth.instance.currentUser?.uid;
    if (companyId == null) return; // Không có userId thì thoát luôn

    try {
      // Đường dẫn Firestore cho nhân viên
      DocumentReference companyRef =
      FirebaseFirestore.instance.collection("companies").doc(companyId);
      DocumentSnapshot companyDoc = await companyRef.get();

      if (companyDoc.exists) {
        // Lấy danh sách token hiện tại
        List<String> tokens = List<String>.from(companyDoc['fcmTokens'] ?? []);

        if (!tokens.contains(newToken)) {
          // Nếu token chưa tồn tại thì thêm vào danh sách
          await companyRef.update({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Nếu tài liệu của nhân viên chưa tồn tại, tạo mới với danh sách token
        await companyRef.set({
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
                    kIsWeb
                        ? 'assets/images/two_circle.png' // ảnh dành cho Web
                        : 'assets/images/two_circle_blue.png',    // ảnh cho mobile
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
                    color: Colors.white,
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

                _buildTextField1(
                  controller: _passController,
                  label: 'Mật khẩu',
                  stream: _authBloc.passStream,
                  isPassword: true, // Đặt cờ này để kích hoạt biểu tượng con mắt
                ),

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
                      backgroundColor:
                      secondaryColor,
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
                      "Đăng nhập",
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.w700,
                        fontSize: 7.sp,
                        color: Colors.white,
                      ),
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
            color: Colors.black,
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

        _buildTextField1(
          controller: _passController,
          label: 'Mật khẩu',
          stream: _authBloc.passStream,
          isPassword: true, // Đặt cờ này để kích hoạt biểu tượng con mắt
        ),

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
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
                    hintStyle: TextStyle(fontSize: isLandscape ? 6.sp : 14.sp),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Hủy",
                        style: TextStyle(fontSize: isLandscape ? 5.sp : 14.sp),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String email = emailController.text.trim();
                        print("Email nhập vào: $email");

                        if (email.isEmpty) {
                          _showCustomSnackBar(
                            context,
                            "Vui lòng nhập địa chỉ email!",
                            Colors.red,
                            Icons.error,
                          );
                          return;
                        }

                        LoadingDialog.showLoadingDialog(context, "Đang kiểm tra...");

                        try {
                          final firestore = FirebaseFirestore.instance;

                          // Tìm trong 3 collection
                          final queries = await Future.wait([
                            firestore.collection('staffs').where('email', isEqualTo: email).get(),
                            firestore.collection('residents').where('email', isEqualTo: email).get(),
                            firestore.collection('companies').where('email', isEqualTo: email).get(),
                          ]);

                          if (!mounted) return;

                          Navigator.pop(context); // Đóng loading dialog

                          final found = queries.any((q) => q.docs.isNotEmpty);
                          if (!found) {
                            _showCustomSnackBar(
                              context,
                              "Email này không tồn tại trong hệ thống!",
                              Colors.red,
                              Icons.error,
                            );
                            return;
                          }

                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          _showCustomSnackBar(
                            context,
                            "Link đặt lại mật khẩu đã được gửi!",
                            Colors.green,
                            Icons.check_circle,
                          );
                          Navigator.pop(context); // Đóng bottom sheet sau khi gửi thành công
                        } catch (error) {
                          print("Lỗi khi gửi link reset: $error");
                          if (mounted) {
                            Navigator.pop(context); // Đóng loading
                            _showCustomSnackBar(
                              context,
                              "Có lỗi xảy ra: $error",
                              Colors.red,
                              Icons.error,
                            );
                          }
                        }
                      },
                      child: Text(
                        "Gửi",
                        style: TextStyle(fontSize: isLandscape ? 5.sp : 14.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Future<Map<String, dynamic>?> getUserInfoWithRole(String userId) async {
    final collections = ['staffs', 'residents', 'companies', 'admins'];

    for (final collection in collections) {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        final role = doc.get('role');
        final isExit = doc.data()!.containsKey('isExit') ? doc.get('isExit') == true : false;

        return {
          'role': role,
          'isExit': isExit,
        };
      }
    }

    return null;
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

              // Lấy thông tin role và isExit
              final userInfo = await getUserInfoWithRole(userId);
              int? role = userInfo?['role'];
              bool isExit = userInfo?['isExit'] ?? false;

              bool isMobile = !kIsWeb;

              if (role == 1) {
                if (isMobile) {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                  if (newToken != null) {
                    await _saveTokenAdminToFirestore(newToken);
                  }
                }
              } else if (role == 2) {
                if (isExit) {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn hiện không khả dụng",
                  );
                  return;
                }

                if (isMobile) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeFirstKTVPage()),
                  );
                  if (newToken != null) {
                    await _saveTokenToFirestore(newToken);
                  }
                } else {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                }
              } else if (role == 3) {
                if (isMobile) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeFirstCSNPage()),
                  );
                  if (newToken != null) {
                    await _saveTokenToFirestore(newToken);
                  }
                } else {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                }
              } else if (role == 4) {
                if (isExit) {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn hiện không khả dụng",
                  );
                  return;
                }

                if (isMobile) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeFirstResidentPage()),
                  );
                  if (newToken != null) {
                    await _saveResidentTokenToFirestore(newToken);
                  }
                } else {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                }
              } else if (role == 5) {
                if (isExit) {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn hiện không khả dụng",
                  );
                  return;
                }

                if (isMobile) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeFirstCompanyPage()),
                  );
                  if (newToken != null) {
                    await _saveTokenCompanyToFirestore(newToken);
                  }
                } else {
                  MsgDialog.showMsgDialog(
                    context,
                    "Thông báo",
                    "Tài khoản của bạn không hỗ trợ đăng nhập trên web",
                  );
                }
              } else {
                MsgDialog.showMsgDialog(
                  context,
                  "Lỗi",
                  "Không tìm thấy role cho tài khoản này",
                );
              }
            } else {
              MsgDialog.showMsgDialog(
                context,
                "Lỗi",
                "Xác thực người dùng không thành công",
              );
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
              style: TextStyle(
                fontSize: 18,
                color: kIsWeb ? Colors.white : Colors.black87, // ⬅ thay đổi màu chữ
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: isLandscape ? 4.sp : 15.sp,
                  color: kIsWeb ? Colors.white : Colors.black87, // ⬅ thay đổi màu label
                ),
                errorText: snapshot.hasError ? snapshot.error as String : null,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 2.h,
                  horizontal: isLandscape ? 8.w : 24.w,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.w),
                  borderRadius: BorderRadius.all(Radius.circular(30.r)),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildTextField1({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
    bool isPassword = false,
  }) {
    return Builder(builder: (context) {
      final size = MediaQuery.of(context).size;
      final isLandscape = size.height < size.width;
      final ValueNotifier<bool> obscureTextNotifier = ValueNotifier<bool>(isPassword);

      return Padding(
        padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
        child: StreamBuilder<String>(
          stream: stream,
          builder: (context, snapshot) {
            return ValueListenableBuilder<bool>(
              valueListenable: obscureTextNotifier,
              builder: (context, obscureText, child) {
                return TextField(
                  controller: controller,
                  obscureText: isPassword ? obscureText : false,
                  style: TextStyle(
                    fontSize: 18,
                    color: kIsWeb ? Colors.white : Colors.black54, // màu chữ
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      fontSize: isLandscape ? 4.sp : 15.sp,
                      color: kIsWeb ? Colors.white : Colors.black87, // màu label
                    ),
                    errorText: snapshot.hasError ? snapshot.error as String : null,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 2.h,
                      horizontal: isLandscape ? 8.w : 24.w,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1.w),
                      borderRadius: BorderRadius.all(Radius.circular(30.r)),
                    ),
                    suffixIcon: isPassword
                        ? Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          obscureTextNotifier.value = !obscureTextNotifier.value;
                        },
                      ),
                    )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
}
