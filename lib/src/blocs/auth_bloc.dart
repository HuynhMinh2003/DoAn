import 'dart:async';
import 'dart:math';
import 'package:do_an/src/fire_base/fire_base_auth.dart';

class AuthBloc {
  final _firAuth = FirAuth();

  final StreamController<String> _nameCompanyController = StreamController<String>.broadcast();
  final StreamController<String> _emailCompanyController = StreamController<String>.broadcast();
  final StreamController<String> _phoneCompanyController = StreamController<String>.broadcast();
  final StreamController<String> _typeCompanyController = StreamController<String>.broadcast();
  final StreamController<String> _describeCompanyController = StreamController<String>.broadcast();

  Stream<String> get nameCompanyStream => _nameCompanyController.stream;
  Stream<String> get emailCompanyStream => _emailCompanyController.stream;
  Stream<String> get phoneCompanyStream => _phoneCompanyController.stream;
  Stream<String> get typeCompanyStream => _typeCompanyController.stream;
  Stream<String> get describeCompanyStream => _describeCompanyController.stream;

  final StreamController<String> _nameStaffController = StreamController<String>.broadcast();
  final StreamController<String> _emailStaffController = StreamController<String>.broadcast();
  final StreamController<String> _phoneStaffController = StreamController<String>.broadcast();
  final StreamController<String> _rollStaffController = StreamController<String>.broadcast();

  Stream<String> get nameStaffStream => _nameStaffController.stream;
  Stream<String> get emailStaffStream => _emailStaffController.stream;
  Stream<String> get phoneStaffStream => _phoneStaffController.stream;
  Stream<String> get rollStaffStream => _rollStaffController.stream;

  final StreamController<String> _emailCompanyController1 = StreamController<String>.broadcast();
  final StreamController<String> _passCompanyController1 = StreamController<String>.broadcast();

  Stream<String> get emailStream => _emailCompanyController1.stream;
  Stream<String> get passStream => _passCompanyController1.stream;

  /// Tạo mật khẩu ngẫu nhiên
  String generateRandomPassword({int length = 10}) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$";
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Kiểm tra dữ liệu hợp lệ (không cần kiểm tra password nếu không nhập từ form)
  bool isValidSignUp(
      String nameCompany,
      String emailCompany,
      String phoneCompany,
      String typeCompany,
      String describeCompany,
      ) {
    bool isValid = true;

    if (nameCompany.isEmpty) {
      _nameCompanyController.sink.addError("Phải nhập tên công ty !");
      isValid = false;
    } else {
      _nameCompanyController.sink.add("");
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (emailCompany.isEmpty) {
      _emailCompanyController.sink.addError("Phải nhập email công ty!");
      isValid = false;
    } else if (!emailRegex.hasMatch(emailCompany)) {
      _emailCompanyController.sink.addError("Email không hợp lệ !");
      isValid = false;
    } else {
      _emailCompanyController.sink.add("");
    }

    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (phoneCompany.isEmpty) {
      _phoneCompanyController.sink.addError("Phải nhập số điện thoại công ty !");
      isValid = false;
    } else if (!phoneRegex.hasMatch(phoneCompany)) {
      _phoneCompanyController.sink.addError("Số điện thoại không hợp lệ !");
      isValid = false;
    } else {
      _phoneCompanyController.sink.add("");
    }

    if (typeCompany.isEmpty) {
      _typeCompanyController.sink.addError("Phải điền loại dịch vụ !");
      isValid = false;
    } else {
      _typeCompanyController.sink.add("");
    }

    if (describeCompany.isEmpty) {
      _describeCompanyController.sink.addError("Phải điền loại dịch vụ !");
      isValid = false;
    } else {
      _describeCompanyController.sink.add("");
    }

    return isValid;
  }

  /// Đăng ký công ty
  void signUpCompany({
    required String nameCompany,
    required String emailCompany,
    required String phoneCompany,
    required String typeCompany,
    required String describeCompany,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    if (isValidSignUp(nameCompany, emailCompany, phoneCompany, typeCompany, describeCompany)) {
      final randomPassword = generateRandomPassword(); // 👉 tạo mật khẩu tại đây

      _firAuth.signUpCompany(
        nameCompany: nameCompany,
        emailCompany: emailCompany,
        phoneCompany: phoneCompany,
        typeCompany: typeCompany,
        describeCompany: describeCompany,
        password: randomPassword,
        onSuccess: () {
          // 👉 Gọi onSuccess() và có thể gửi mật khẩu về Gmail tại đây
          print('Mật khẩu ngẫu nhiên là: $randomPassword');
          onSuccess();
        },
        onRegisterError: onRegisterError,
      );
    }
  }

  bool isValidSignIn(String email, String pass) {
    bool isValid1 = true;

    final emailRegex1 = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (email.isEmpty) {
      _emailCompanyController1.sink.addError("Phải nhập email !");
      isValid1 = false;
    } else if (!emailRegex1.hasMatch(email)) {
      _emailCompanyController1.sink.addError("Email không hợp lệ !");
      isValid1 = false;
    } else {
      _emailCompanyController1.sink.add("");
    }

    if (pass.isEmpty) {
      _passCompanyController1.sink.addError("Mật khẩu không được để trống !");
      isValid1 = false;
    } else {
      _passCompanyController1.sink.add("");
    }

    return isValid1;
  }

  void signInCompany({
    required String email,
    required String pass,
    required Function onSuccess,
    required Function(String) onSignInError,
  }) {
    if (isValidSignIn(email, pass)) {
      _firAuth.signInCompany(
        email: email,
        password: pass,
        onSuccess: onSuccess,
        onSignInError: onSignInError,
      );
    }
  }

  void dispose() {
    _nameCompanyController.close();
    _emailCompanyController.close();
    _phoneCompanyController.close();
    _typeCompanyController.close();
    _describeCompanyController.close();
  }
}
