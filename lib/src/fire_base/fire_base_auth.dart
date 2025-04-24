import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Đăng ký người dùng mới
  void signUpCompany({
    required String nameCompany,
    required String emailCompany,
    required String phoneCompany,
    required String typeCompany,
    required String describeCompany,
    required String password,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    _firebaseAuth
        .createUserWithEmailAndPassword(email: emailCompany, password: password)
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
        onRegisterError("Tạo công ty thất bại!");
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
    String? fcmToken = await FirebaseMessaging.instance.getToken(); // Lấy FCM Token

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    final companyData = {
      "nameCompany": nameCompany,
      "emailCompany": emailCompany,
      "phoneCompany": phoneCompany,
      "typeCompany": typeCompany,
      "describeCompany": describeCompany,
      "fcmToken": fcmToken,
      "createdAt": DateTime.now().toIso8601String(),
    };

    dbRef.child("companies").child(companyId).set(companyData).then((_) {
      onSuccess();
    }).catchError((error) {
      onRegisterError("Lỗi khi lưu thông tin công ty.");
    });
  }

  void signUpStaff({
    required String name,
    required String email,
    required String phone,
    required String position,
    required String password,
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((userCredential) async {
      var user = userCredential.user;
      if (user != null) {
        _createStaff(
          user.uid,
          name,
          email,
          phone,
          position,
          onSuccess,
          onRegisterError,
        );
      } else {
        onRegisterError("Tạo tài khoản thất bại!");
      }
    }).catchError((err) {
      _onSignUpErr(err.code, onRegisterError);
    });
  }

  void _createStaff(
      String userId,
      String name,
      String email,
      String phone,
      String position,
      Function onSuccess,
      Function(String) onRegisterError,
      ) async {
    try {
      final staffData = {
        "name": name,
        "email": email,
        "phone": phone,
        "position": position,
        "role": 2,
        "isFree": 1,
        "createdAt": Timestamp.now(), // Dùng Timestamp của Firestore
      };

      await FirebaseFirestore.instance.collection("staffs").doc(userId).set(staffData);
      onSuccess();
    } catch (e) {
      onRegisterError("Lỗi khi lưu thông tin nhân viên.");
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
