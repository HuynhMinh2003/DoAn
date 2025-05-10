import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Đăng ký người dùng mới
  void signUpCompany({
    required String nameCompany,
    required String emailCompany,
    required String phoneCompany,
    required String typeCompany,
    required String describeCompany,
    required String passwordCompany,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    _firebaseAuth
        .createUserWithEmailAndPassword(email: emailCompany, password: passwordCompany)
        .then((userCredential) async {
      var company = userCredential.user;
      if (company != null) {
        _createCompany(
          company.uid,
          nameCompany,
          emailCompany,
          phoneCompany,
          typeCompany,
          describeCompany,
          onSuccess,
          onRegisterError,
        );
      } else {
        onRegisterError("Tạo tài khoản công ty thất bại!");
      }
    }).catchError((err) {
      _onSignUpErr(err.code, onRegisterError);
    });
  }

  /// Lưu thông tin người dùng vào Firebase Realtime Database
  void _createCompany(
      String companyId,
      String nameCompany,
      String emailCompany,
      String phoneCompany,
      String typeCompany,
      String describeCompany,
      Function onSuccess,
      Function(String) onRegisterError,
      ) async {
    try{
      final companyData = {
        "name": nameCompany,
        "email": emailCompany,
        "phone": phoneCompany,
        "type": typeCompany,
        "describe": describeCompany,
        "role": 4,
        "createdAt": DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance.collection("companies").doc(companyId).set(companyData);
      onSuccess();
    } catch (e) {
      onRegisterError("Lỗi khi lưu thông tin công ty");
    }
  }

  void signUpStaff({
    required String nameStaff,
    required String addressStaff,
    required String cccdStaff,
    required String gender,
    required String emailStaff,
    required String phoneStaff,
    required String position,
    required String imageUrlStaff,
    required String passwordStaff,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    _firebaseAuth
        .createUserWithEmailAndPassword(email: emailStaff, password: passwordStaff)
        .then((userCredential) async {
      var staff = userCredential.user;
      if (staff != null) {
        _createStaff(
          staff.uid,
          nameStaff,
          addressStaff,
          cccdStaff,
          emailStaff,
          phoneStaff,
          position,
          imageUrlStaff,
          onSuccess,
          onRegisterError,
        );
      } else {
        onRegisterError("Tạo tài khoản nhân viên thất bại!");
      }
    }).catchError((err) {
      _onSignUpErr(err.code, onRegisterError);
    });
  }

  void _createStaff(
      String userId,
      String nameStaff,
      String addressStaff,
      String cccdStaff,
      String emailStaff,
      String phoneStaff,
      String position,
      String imageUrlStaff,
      Function onSuccess,
      Function(String) onRegisterError,
      ) async {
    try {
      final staffData = {
        "name": nameStaff,
        "address": addressStaff,
        "cccd": cccdStaff,
        "email": emailStaff,
        "phone": phoneStaff,
        "position": position,
        "role": 2,
        "isFree": true,
        "imageUrl": imageUrlStaff,
        "fcmTokens": [], // Thêm fcmToken dưới dạng chuỗi rỗng
        "createdAt": Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection("staffs").doc(userId).set(staffData);
      onSuccess();
    } catch (e) {
      onRegisterError("Lỗi khi lưu thông tin nhân viên");
    }
  }

  /// Đăng nhập người dùng
  void signIn({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onSignInError,
  }) {
    _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((userCredential) async {
      var user = userCredential.user;
      if (user != null) {
        onSuccess();
      } else {
        onSignInError("Không tìm thấy người dùng !");
      }
    }).catchError((err) {
      _onSignInErr(err.code, onSignInError);
    });
  }

  /// Xử lý lỗi đăng ký
  void _onSignUpErr(String code, Function(String) onRegisterError) {
    switch (code) {
      case "email-already-in-use":
        onRegisterError("Địa chỉ email này đã được sử dụng");
        break;
      case "invalid-email":
        onRegisterError("Địa chỉ email không hợp lệ");
        break;
      case "weak-password":
        onRegisterError("Mật khẩu không đủ mạnh");
        break;
      case "operation-not-allowed":
        onRegisterError("Tài khoản email/mật khẩu không được kích hoạt");
        break;
      case "too-many-requests":
        onRegisterError("Quá nhiều yêu cầu. Vui lòng thử lại sau");
        break;
      case "network-request-failed":
        onRegisterError("Lỗi mạng. Vui lòng kiểm tra kết nối của bạn");
        break;
      default:
        onRegisterError("Đăng kí thất bại, vui lòng thử lại");
        break;
    }
  }

  /// Xử lý lỗi đăng nhập
  void _onSignInErr(String code, Function(String) onSignInError) {
    switch (code) {
      case "user-not-found":
        onSignInError("Không tìm thấy người dùng với email này");
        break;
      case "wrong-password":
        onSignInError("Mật khẩu không đúng");
        break;
      case "invalid-email":
        onSignInError("Email không hợp lệ");
        break;
      case "user-disabled":
        onSignInError("Tài khoản này đã bị vô hiệu hóa");
        break;
      case "network-request-failed":
        onSignInError("Lỗi mạng. Vui lòng kiểm tra kết nối");
        break;
      default:
        onSignInError("Đăng nhập thất bại. Vui lòng thử lại");
        break;
    }
  }
}
