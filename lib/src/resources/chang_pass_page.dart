import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  bool _isLoading = false;

  // Hàm kiểm tra mật khẩu cũ và thay đổi mật khẩu
  Future<void> _changePassword() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Lấy người dùng hiện tại
      User? user = _auth.currentUser;

      if (user == null) {
        _showSnackBar('Bạn cần phải đăng nhập để thay đổi mật khẩu.');
        return;
      }

      String oldPassword = _oldPasswordController.text;
      String newPassword = _newPasswordController.text;
      String confirmPassword = _confirmPasswordController.text;

      if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        _showSnackBar('Vui lòng điền đầy đủ thông tin.');
        return;
      }

      if (newPassword.length < 6) {
        _showSnackBar('Mật khẩu mới phải có ít nhất 6 ký tự.');
        return;
      }

      if (newPassword != confirmPassword) {
        _showSnackBar('Mật khẩu mới và mật khẩu xác nhận không khớp.');
        return;
      }

      if (newPassword == oldPassword) {
        _showSnackBar('Mật khẩu mới không được trùng với mật khẩu cũ.');
        return;
      }
      // Tạo credential từ email và mật khẩu cũ
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      // Thực hiện reauthentication
      await user.reauthenticateWithCredential(credential);

      // Nếu mật khẩu cũ đúng, thay đổi mật khẩu
      await user.updatePassword(newPassword);
      await user.reload();
      user = _auth.currentUser; // Refresh lại user info

      _showSnackBar('Mật khẩu đã được thay đổi thành công.');

      // Đợi một chút trước khi quay lại trang trước
      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } catch (e) {
      _showSnackBar('Đã có lỗi xảy ra. Vui lòng thử lại sau.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm xử lý lỗi FirebaseAuthException và chuyển thành tiếng Việt
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

  // Hàm hiển thị SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Text('Đổi Mật Khẩu'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu cũ',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Đổi Mật Khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}
