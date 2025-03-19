import 'dart:async';
import 'package:do_an/src/fire_base/fire_base_auth.dart';

class AuthBloc {
  final _firAuth = FirAuth();

  final StreamController<String> _nameController = StreamController<String>();
  final StreamController<String> _cccdController = StreamController<String>();
  final StreamController<DateTime> _birthDateController = StreamController<DateTime>(); // Sửa thành DateTime
  final StreamController<String> _emailController = StreamController<String>();
  final StreamController<String> _phoneController = StreamController<String>();
  final StreamController<String> _nameHouseController = StreamController<String>();
  final StreamController<String> _passController = StreamController<String>();
  final StreamController<double> _apartmentAreaController = StreamController<double>(); // New controller for apartment area

  Stream<String> get nameStream => _nameController.stream;
  Stream<String> get cccdStream => _cccdController.stream;
  Stream<DateTime> get birthDateStream => _birthDateController.stream; // Sửa thành DateTime
  Stream<String> get emailStream => _emailController.stream;
  Stream<String> get phoneStream => _phoneController.stream;
  Stream<String> get nameHouseStream => _nameHouseController.stream;
  Stream<String> get passStream => _passController.stream;
  Stream<double> get apartmentAreaStream => _apartmentAreaController.stream;

  final StreamController<String> _emailController1 = StreamController<String>();
  final StreamController<String> _passController1 = StreamController<String>();

  Stream<String> get emailStream1 => _emailController1.stream;
  Stream<String> get passStream1 => _passController1.stream;// New stream for apartment area

  /// Kiểm tra dữ liệu hợp lệ
  bool isValid(
      String name,
      String cccd,
      DateTime? birthDate, // Chuyển thành DateTime
      String email,
      String phone,
      String? nameHouse,
      String pass,
      double apartmentArea, // Add apartment area to validation
      ) {
    bool isValid = true;

    // Kiểm tra tên
    if (name.isEmpty) {
      _nameController.sink.addError("Phải nhập tên !");
      isValid = false;
    } else {
      _nameController.sink.add(""); // Xóa lỗi nếu hợp lệ
    }

    // Kiểm tra email
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (email.isEmpty) {
      _emailController.sink.addError("Phải nhập email !");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailController.sink.addError("Email không hợp lệ !");
      isValid = false;
    } else {
      _emailController.sink.add("");
    }

    // Kiểm tra mật khẩu
    if (pass.isEmpty) {
      _passController.sink.addError("Phải nhập mật khẩu !");
      isValid = false;
    } else if (pass.length < 6) {
      _passController.sink.addError("Mật khẩu phải có ít nhất 6 ký tự !");
      isValid = false;
    } else {
      _passController.sink.add("");
    }

    // Kiểm tra số điện thoại
    final phoneRegex = RegExp(r'^\d{10,15}$'); // Chỉ số từ 10 đến 15 chữ số
    if (phone.isEmpty) {
      _phoneController.sink.addError("Phải nhập số điện thoại !");
      isValid = false;
    } else if (!phoneRegex.hasMatch(phone)) {
      _phoneController.sink.addError("Số điện thoại không hợp lệ !");
      isValid = false;
    } else {
      _phoneController.sink.add("");
    }

    // Kiểm tra số cccd
    final cccdRegex = RegExp(r'^\d{12}$'); // Biểu thức kiểm tra đúng 12 chữ số
    if (cccd.isEmpty) {
      _cccdController.sink.addError("Phải nhập số CCCD !");
      isValid = false;
    } else if (!cccdRegex.hasMatch(cccd)) {
      _cccdController.sink.addError("Số CCCD không hợp lệ !");
      isValid = false;
    } else {
      _cccdController.sink.add("");
    }

    // Kiểm tra tên căn hộ
    if (nameHouse == null || nameHouse.isEmpty) {
      _nameHouseController.sink.addError("Phải chọn tên căn hộ !");
      isValid = false;
    } else {
      _nameHouseController.sink.add(""); // Xóa lỗi nếu hợp lệ
    }

    // Kiểm tra ngày sinh
    if (birthDate == null) {
      _birthDateController.sink.addError("Phải nhập ngày sinh !");
      isValid = false;
    } else {
      _birthDateController.sink.add(birthDate); // Phát ngày sinh vào Stream
    }

    // Kiểm tra diện tích căn hộ
    if (apartmentArea <= 0) {
      _apartmentAreaController.sink.addError("Diện tích căn hộ không hợp lệ !");
      isValid = false;
    } else {
      _apartmentAreaController.sink.add(apartmentArea); // Phát diện tích vào Stream
    }

    return isValid;
  }

  /// Đăng ký người dùng
  void signUp({
    required String name,
    required String cccd,
    required DateTime? birthDate, // birthDate có thể là null
    required String email,
    required String phone,
    required String nameHouse, // Thêm tham số
    required String pass,
    required double apartmentArea, // Add apartmentArea parameter
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    if (isValid(name, cccd, birthDate, email, phone, nameHouse, pass, apartmentArea)) {
      // Kiểm tra nếu birthDate không phải là null, nếu không thì dùng giá trị mặc định
      DateTime finalBirthDate = birthDate ?? DateTime(2000, 01, 01); // Sử dụng giá trị mặc định nếu null

      _firAuth.signUp(
        name: name,
        cccd: cccd,
        birthDate: finalBirthDate, // Gửi giá trị birthDate đã chuyển thành chuỗi
        email: email,
        phone: phone,
        nameHouse: nameHouse,
        password: pass,
        area: apartmentArea, // Gửi diện tích căn hộ vào signUp
        onSuccess: onSuccess,
        onRegisterError: onRegisterError,
      );
    }
  }

  bool isValidSignIn(String email, String pass) {
    bool isValid1 = true;

    final emailRegex1 = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (email.isEmpty) {
      _emailController1.sink.addError("Phải nhập email !");
      isValid1 = false;
    } else if (!emailRegex1.hasMatch(email)) {
      _emailController1.sink.addError("Email không hợp lệ !");
      isValid1 = false;
    } else {
      _emailController1.sink.add(""); // Xóa lỗi nếu hợp lệ
    }

    if (pass.isEmpty) {
      _passController1.sink.addError("Mật khẩu không được để trống !");
      isValid1 = false;
    } else {
      _passController1.sink.add(""); // Xóa lỗi nếu hợp lệ
    }

    return isValid1;
  }


  /// Đăng nhập người dùng
  void signIn({
    required String email,
    required String pass,
    required Function onSuccess,
    required Function(String) onSignInError,
  }) {
    if (isValidSignIn(email, pass)) {
      _firAuth.signIn(
        email: email,
        password: pass,
        onSuccess: onSuccess,
        onSignInError: onSignInError,
      );
    }
  }

  /// Đóng các StreamController
  void dispose() {
    _nameController.close();
    _cccdController.close();
    _birthDateController.close();
    _emailController.close();
    _phoneController.close();
    _nameController.close();
    _passController.close();
    _apartmentAreaController.close(); // Close the new controller
  }
}
