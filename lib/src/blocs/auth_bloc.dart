import 'dart:async';
import 'dart:math';
import 'package:do_an/src/fire_base/fire_base_auth.dart';

class AuthBloc {
  final _firAuth = FirAuth();

  // công ty
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

  // nhân viên
  final StreamController<String> _nameStaffController = StreamController<String>.broadcast();
  final StreamController<String> _emailStaffController = StreamController<String>.broadcast();
  final StreamController<String> _phoneStaffController = StreamController<String>.broadcast();
  final StreamController<String> _addressStaffController = StreamController<String>.broadcast();
  final StreamController<String> _cccdStaffController = StreamController<String>.broadcast();

  Stream<String> get nameStaffStream => _nameStaffController.stream;
  Stream<String> get emailStaffStream => _emailStaffController.stream;
  Stream<String> get phoneStaffStream => _phoneStaffController.stream;
  Stream<String> get addressStaffStream => _addressStaffController.stream;
  Stream<String> get cccdStaffStream => _cccdStaffController.stream;

  // cư dân
  final StreamController<String>  _nameResidentController = StreamController<String>.broadcast();
  final StreamController<String> _cccdResidentController = StreamController<String>.broadcast();
  final StreamController<String>  _phoneResidentController = StreamController<String>.broadcast();
  final StreamController<String>  _emailResidentController = StreamController<String>.broadcast();
  final StreamController<String>  _addressResidentController = StreamController<String>.broadcast();

  final _birthDateController = StreamController<DateTime?>.broadcast();

  Stream<DateTime?> get birthDateStream => _birthDateController.stream;
  Stream<String> get nameResidentStream => _nameResidentController.stream;
  Stream<String> get cccdResidentStream => _cccdResidentController.stream;
  Stream<String> get phoneResidentStream => _phoneResidentController.stream;
  Stream<String> get emailResidentStream => _emailResidentController.stream;
  Stream<String> get addressResidentStream => _addressResidentController.stream;

  // login chung
  final StreamController<String> _emailController = StreamController<String>.broadcast();
  final StreamController<String> _passController = StreamController<String>.broadcast();

  Stream<String> get emailStream => _emailController.stream;
  Stream<String> get passStream => _passController.stream;

  void updateBirthDate(DateTime? birthDate) {
    _birthDateController.sink.add(birthDate); // Cập nhật giá trị ngày sinh
  }

  void clearNameResidentError() {
    _nameResidentController.sink.add(""); // xóa lỗi bằng cách đẩy lại giá trị trống
  }

  void clearEmailResidentError() {
    _emailResidentController.sink.add(""); // xóa lỗi bằng cách đẩy lại giá trị trống
  }

  void clearPhoneResidentError() {
    _phoneResidentController.sink.add(""); // xóa lỗi bằng cách đẩy lại giá trị trống
  }

  void clearCccdResidentError() {
    _cccdResidentController.sink.add(""); // xóa lỗi bằng cách đẩy lại giá trị trống
  }

  void clearAddressResidentError() {
    _addressResidentController.sink.add(""); // xóa lỗi bằng cách đẩy lại giá trị trống
  }



  /// Tạo mật khẩu ngẫu nhiên
  String generateRandomPassword({int length = 10}) {
    const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$";
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Kiểm tra dữ liệu hợp lệ (không cần kiểm tra password nếu không nhập từ form)
  bool isValidCompanySignUp(
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
    if (isValidCompanySignUp(nameCompany, emailCompany, phoneCompany, typeCompany, describeCompany)) {
      final randomPassword = generateRandomPassword(); // 👉 tạo mật khẩu tại đây

      _firAuth.signUpCompany(
        nameCompany: nameCompany,
        emailCompany: emailCompany,
        phoneCompany: phoneCompany,
        typeCompany: typeCompany,
        describeCompany: describeCompany,
        passwordCompany: randomPassword,
        onSuccess: () {
          // 👉 Gọi onSuccess() và có thể gửi mật khẩu về Gmail tại đây
          print('Mật khẩu ngẫu nhiên là: $randomPassword');
          onSuccess();
        },
        onRegisterError: onRegisterError,
      );
    }
  }

  /// Đăng ký nhân viên
  void signUpStaff({
    required String nameStaff,
    required String addressStaff,
    required String cccdStaff,
    required String gender,
    required String emailStaff,
    required String phoneStaff,
    required String position,
    required String imageUrlStaff,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    if (isValidStaffSignUp(nameStaff, addressStaff, cccdStaff, gender, emailStaff, phoneStaff, position)) {
      final randomPassword = generateRandomPassword();

      _firAuth.signUpStaff(
        nameStaff: nameStaff,
        addressStaff: addressStaff,
        cccdStaff: cccdStaff,
        gender: gender,
        emailStaff: emailStaff,
        phoneStaff: phoneStaff,
        position: position,
        imageUrlStaff: imageUrlStaff,
        passwordStaff: randomPassword,
        onSuccess: () {
          print('Mật khẩu ngẫu nhiên cho nhân viên là: $randomPassword');
          onSuccess();
        },
        onRegisterError: onRegisterError,
      );
    }
  }

  bool isValidStaffSignUp(String name, String address,String cccd, String gender, String email, String phone, String position) {
    bool isValid = true;

    if (name.isEmpty) {
      _nameStaffController.sink.addError("Phải nhập tên nhân viên!");
      isValid = false;
    } else {
      _nameStaffController.sink.add("");
    }

    if (address.isEmpty) {
      _addressStaffController.sink.addError("Phải nhập địa chỉ!");
      isValid = false;
    } else {
      _addressStaffController.sink.add("");
    }

    final cccdRegex = RegExp(r'^\d{12}$');
    if (cccd.isEmpty) {
      _cccdStaffController.sink.addError("Phải nhập số CCCD !");
      isValid = false;
    } else if (!cccdRegex.hasMatch(cccd)) {
      _cccdStaffController.sink.addError("Số CCCD không hợp lệ !");
      isValid = false;
    } else {
      _cccdStaffController.sink.add("");
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (email.isEmpty) {
      _emailStaffController.sink.addError("Phải nhập email!");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailStaffController.sink.addError("Email không hợp lệ!");
      isValid = false;
    } else {
      _emailStaffController.sink.add("");
    }

    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (phone.isEmpty) {
      _phoneStaffController.sink.addError("Phải nhập số điện thoại!");
      isValid = false;
    } else if (!phoneRegex.hasMatch(phone)) {
      _phoneStaffController.sink.addError("Số điện thoại không hợp lệ!");
      isValid = false;
    } else {
      _phoneStaffController.sink.add("");
    }

    return isValid;
  }

  bool isValidStaffUpdate(String name, String address,String cccd, String gender, String email,String phone, String position) {
    bool isValid = true;

    if (name.isEmpty) {
      _nameStaffController.sink.addError("Phải nhập tên nhân viên!");
      isValid = false;
    } else {
      _nameStaffController.sink.add("");
    }

    if (address.isEmpty) {
      _addressStaffController.sink.addError("Phải nhập địa chỉ!");
      isValid = false;
    } else {
      _addressStaffController.sink.add("");
    }

    final cccdRegex = RegExp(r'^\d{12}$');
    if (cccd.isEmpty) {
      _cccdStaffController.sink.addError("Phải nhập số CCCD !");
      isValid = false;
    } else if (!cccdRegex.hasMatch(cccd)) {
      _cccdStaffController.sink.addError("Số CCCD không hợp lệ !");
      isValid = false;
    } else {
      _cccdStaffController.sink.add("");
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (email.isEmpty) {
      _emailStaffController.sink.addError("Phải nhập email!");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailStaffController.sink.addError("Email không hợp lệ!");
      isValid = false;
    } else {
      _emailStaffController.sink.add("");
    }

    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (phone.isEmpty) {
      _phoneStaffController.sink.addError("Phải nhập số điện thoại!");
      isValid = false;
    } else if (!phoneRegex.hasMatch(phone)) {
      _phoneStaffController.sink.addError("Số điện thoại không hợp lệ!");
      isValid = false;
    } else {
      _phoneStaffController.sink.add("");
    }

    return isValid;
  }

  bool isValidResidentSignUp(
      String nameResident,
      String emailResident,
      String phoneResident,
      String cccdResident,
      String addressResident,
      String genderResident,
      DateTime? birthDate,
      ) {
    bool isValid = true;

    if (nameResident.isEmpty) {
      _nameResidentController.sink.addError("Phải nhập tên cư dân !");
      isValid = false;
    } else {
      _nameResidentController.sink.add("");
    }

    if (addressResident.isEmpty) {
      _addressResidentController.sink.addError("Phải nhập địa chỉ cư dân !");
      isValid = false;
    } else {
      _addressResidentController.sink.add("");
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (emailResident.isEmpty) {
      _emailResidentController.sink.addError("Phải nhập email cư dân!");
      isValid = false;
    } else if (!emailRegex.hasMatch(emailResident)) {
      _emailResidentController.sink.addError("Email không hợp lệ !");
      isValid = false;
    } else {
      _emailResidentController.sink.add("");
    }

    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (phoneResident.isEmpty) {
      _phoneResidentController.sink.addError("Phải nhập số điện thoại cư dân !");
      isValid = false;
    } else if (!phoneRegex.hasMatch(phoneResident)) {
      _phoneResidentController.sink.addError("Số điện thoại không hợp lệ !");
      isValid = false;
    } else {
      _phoneResidentController.sink.add("");
    }

    final cccdRegex = RegExp(r'^\d{12}$');
    if (cccdResident.isEmpty) {
      _cccdResidentController.sink.addError("Phải nhập số CCCD !");
      isValid = false;
    } else if (!cccdRegex.hasMatch(cccdResident)) {
      _cccdResidentController.sink.addError("Số CCCD không hợp lệ !");
      isValid = false;
    } else {
      _cccdResidentController.sink.add("");
    }

    if (birthDate == null) {
      // Nếu ngày sinh trống, phát sự kiện lỗi
      _birthDateController.sink.addError("Ngày sinh không được để trống!");
      isValid = false;
    } else {
      // Nếu có ngày sinh, cập nhật bình thường
      _birthDateController.sink.add(birthDate);
    }

    return isValid;
  }

  bool isValidSignIn(String email, String pass) {
    bool isValid1 = true;

    final emailRegex1 = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (email.isEmpty) {
      _emailController.sink.addError("Phải nhập email !");
      isValid1 = false;
    } else if (!emailRegex1.hasMatch(email)) {
      _emailController.sink.addError("Email không hợp lệ !");
      isValid1 = false;
    } else {
      _emailController.sink.add("");
    }

    if (pass.isEmpty) {
      _passController.sink.addError("Mật khẩu không được để trống !");
      isValid1 = false;
    } else {
      _passController.sink.add("");
    }

    return isValid1;
  }

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

  void changeName(String name) {
    _nameResidentController.sink.add(name); // Trigger UI update
  }
  void changeEmail(String email) {
    _emailResidentController.sink.add(email);
  }
  void changePhone(String phone) {
    _phoneResidentController.sink.add(phone);
  }
  void changeCCCD(String cccd) {
    _cccdResidentController.sink.add(cccd);
  }
  void changeAddress(String address) {
    _addressResidentController.sink.add(address);
  }


  void changeBirthDate(DateTime? date) {
    if (date == null) {
      _birthDateController.sink.addError("Ngày sinh không được để trống!");
    } else {
      _birthDateController.sink.add(date);
    }
  }

  // Controller cho Gender Stream
  final _genderResidentController = StreamController<String>();

  // Getter cho Stream
  Stream<String> get genderResidentStream => _genderResidentController.stream;

  // Phương thức để thay đổi giá trị Gender
  void changeGender(String gender) {
    if (_validateGender(gender)) {
      _genderResidentController.sink.add(gender); // Đẩy giá trị mới vào stream
    } else {
      _genderResidentController.sink.addError('Vui lòng chọn giới tính hợp lệ');
    }
  }

  // Hàm validate giá trị Gender
  bool _validateGender(String gender) {
    return gender == 'Nam' || gender == 'Nữ' || gender == 'Khác';
  }

  void dispose() {
    _nameCompanyController.close();
    _emailCompanyController.close();
    _phoneCompanyController.close();
    _typeCompanyController.close();
    _describeCompanyController.close();

    _nameStaffController.close();
    _emailStaffController.close();
    _phoneStaffController.close();
    _cccdStaffController.close();
    _addressStaffController.close();

    _nameResidentController.close();
    _emailResidentController.close();
    _phoneResidentController.close();
    _cccdResidentController.close();
    _genderResidentController.close();
    _addressResidentController.close();

    _emailController.close();
    _passController.close();
  }

}
