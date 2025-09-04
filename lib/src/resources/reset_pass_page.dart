import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose()
  {
    super.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'wrong-password':
        errorMessage = 'Mật khẩu cũ không chính xác.';
        break;
      case 'weak-password':
        errorMessage = 'Mật khẩu mới quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
        break;
      case 'requires-recent-login':
        errorMessage =
        'Để thay đổi mật khẩu, bạn cần đăng nhập lại. Vui lòng đăng xuất và đăng nhập lại.';
        break;
      case 'too-many-requests':
        errorMessage =
        'Bạn đã thực hiện quá nhiều yêu cầu. Vui lòng thử lại sau một thời gian.';
        break;
      default:
        errorMessage = 'Mật khẩu cũ không chính xác.';
    }
    _showSnackBar(errorMessage);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,style: TextStyle(fontSize: 15.sp),),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changePassword() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      User? user = _auth.currentUser;

      if (user == null) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Bạn cần phải đăng nhập để thay đổi mật khẩu.');
        return;
      }

      String oldPassword = _oldPasswordController.text;
      String newPassword = _newPasswordController.text;
      String confirmPassword = _confirmPasswordController.text;

      if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Vui lòng điền đầy đủ thông tin.');
        return;
      }

      if (newPassword.length < 6) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Mật khẩu mới phải có ít nhất 6 ký tự.');
        return;
      }

      if (newPassword != confirmPassword) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Mật khẩu mới và mật khẩu xác nhận không khớp.');
        return;
      }

      if (newPassword == oldPassword) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Mật khẩu mới không được trùng với mật khẩu cũ.');
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      await user.reload();

      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Mật khẩu đã được thay đổi thành công.');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _handleFirebaseAuthError(e);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Đã có lỗi xảy ra. Vui lòng thử lại sau.');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(title: Text('Đổi mật khẩu', style: TextStyle(color:Colors.white,fontSize: 25.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  labelStyle: TextStyle(fontSize: 15.sp, color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  labelStyle: TextStyle(fontSize: 15.sp, color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  labelStyle: TextStyle(fontSize: 15.sp, color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: 140.w,
                height: 40.h,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black45,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('Đổi mật khẩu', style: TextStyle(fontSize: 15.sp,color:Colors.black)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
