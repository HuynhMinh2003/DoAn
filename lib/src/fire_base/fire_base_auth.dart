import 'package:firebase_auth/firebase_auth.dart';
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
      var user = userCredential.user;
      if (user != null) {
        _createCompany(
          user.uid,
          nameCompany,
          emailCompany,
          phoneCompany,
          typeCompany,
          describeCompany,
          onSuccess,
          onRegisterError,
        );
      } else {
        onRegisterError("User creation failed.");
      }
    }).catchError((err) {
      _onSignUpErr(err.code, onRegisterError);
    });
  }

  /// Lưu thông tin người dùng vào Firebase Realtime Database
  void _createCompany(
      String userId,
      String nameCompany,
      String emailCompany,
      String phoneCompany,
      String typeCompany,
      String describeCompany,
      Function onSuccess,
      Function(String) onRegisterError,
      ) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken(); // Lấy FCM Token

    var company = {
      "nameCompany": nameCompany,
      "emailCompany": emailCompany,
      "phoneCompany": phoneCompany,
      "typeCompany": typeCompany,
      "describeCompany": describeCompany,
      "fcmToken": fcmToken,
    };

    // TODO: Gửi dữ liệu này lên Firebase Realtime Database
    onSuccess(); // Gọi callback thành công
  }

  /// Đăng nhập người dùng
  void signInCompany({
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
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 🔹 Nếu email là 'hmvn2003@gmail.com', bỏ qua kiểm tra
        if (email == 'hmvn2003@gmail.com') {
          onSuccess();
          return;
        }

        // TODO: Xử lý logic xác thực FCM token nếu cần

        onSuccess();
      } else {
        onSignInError("User not found.");
      }
    }).catchError((err) {
      _onSignInErr(err.code, onSignInError);
    });
  }

  /// Xử lý lỗi đăng ký
  void _onSignUpErr(String code, Function(String) onRegisterError) {
    switch (code) {
      case "email-already-in-use":
        onRegisterError("Địa chỉ email này đã được sử dụng.");
        break;
      case "invalid-email":
        onRegisterError("Địa chỉ email không hợp lệ.");
        break;
      case "weak-password":
        onRegisterError("Mật khẩu không đủ mạnh.");
        break;
      case "operation-not-allowed":
        onRegisterError("Tài khoản email/mật khẩu không được kích hoạt.");
        break;
      case "too-many-requests":
        onRegisterError("Quá nhiều yêu cầu. Vui lòng thử lại sau.");
        break;
      case "network-request-failed":
        onRegisterError("Lỗi mạng. Vui lòng kiểm tra kết nối của bạn.");
        break;
      default:
        onRegisterError("Sign up failed, please try again.");
        break;
    }
  }

  /// Xử lý lỗi đăng nhập
  void _onSignInErr(String code, Function(String) onSignInError) {
    switch (code) {
      case "user-not-found":
        onSignInError("Không tìm thấy người dùng với email này.");
        break;
      case "wrong-password":
        onSignInError("Mật khẩu không đúng.");
        break;
      case "invalid-email":
        onSignInError("Email không hợp lệ.");
        break;
      case "user-disabled":
        onSignInError("Tài khoản này đã bị vô hiệu hóa.");
        break;
      case "network-request-failed":
        onSignInError("Lỗi mạng. Vui lòng kiểm tra kết nối.");
        break;
      default:
        onSignInError("Đăng nhập thất bại. Vui lòng thử lại.");
        break;
    }
  }
}
