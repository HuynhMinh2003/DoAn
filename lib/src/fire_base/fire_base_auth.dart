import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Đăng ký người dùng mới
  void signUp({
    required String name,
    required String cccd,
    required DateTime birthDate,
    required String email,
    required String phone,
    required String password,
    required String nameHouse,
    required double area,
    required String avatarUrl, // Ảnh đại diện
    required Function onSuccess,
    required Function(String) onRegisterError,
  }) {
    _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((userCredential) async {
      var user = userCredential.user;
      if (user != null) {
        _createUser(
          user.uid,
          name,
          cccd,
          birthDate,
          email,
          phone,
          nameHouse,
          area,
          "",
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
  void _createUser(
      String userId,
      String name,
      String cccd,
      DateTime birthDate,
      String email,
      String phone,
      String nameHouse,
      double area,
      String avatarUrl, // Thêm ảnh vào database
      Function onSuccess,
      Function(String) onRegisterError,
      ) async{
    String birthDateStr = birthDate.toIso8601String();
    String? fcmToken = await FirebaseMessaging.instance.getToken(); // Lấy FCM Token

    var user = {
      "name": name,
      "cccd": cccd,
      "birthDate": birthDateStr,
      "email": email,
      "phone": phone,
      "nameHouse": nameHouse,
      "area": area.toString(),
      "isApproved": false,
      "role": 0,
      "fcmToken": fcmToken, // Lưu token vào Firestore
      "avatarUrl": avatarUrl, // Lưu URL ảnh
    };

    var ref = FirebaseDatabase.instance.ref().child("users");
    ref.child(userId).set(user).then((_) {
      _createBillingData(userId, nameHouse, area, fcmToken, onSuccess, onRegisterError);
    }).catchError((err) {
      onRegisterError("Sign up failed, please try again.");
    });
  }

  /// Hàm tính giá nước dựa trên bậc tiêu thụ ở Hà Nội
  int calculateWaterPrice(double waterUsage) {
    int waterPrice = 0;

    if (waterUsage <= 10) {
      waterPrice = (waterUsage * 6869).toInt();
    } else if (waterUsage <= 20) {
      waterPrice = (10 * 6869 + (waterUsage - 10) * 8110).toInt();
    } else if (waterUsage <= 30) {
      waterPrice = (10 * 6869 + 10 * 8110 + (waterUsage - 20) * 9969).toInt();
    } else {
      waterPrice = (10 * 6869 + 10 * 8110 + 10 * 9969 + (waterUsage - 30) * 15929).toInt();
    }

    return waterPrice;
  }

  int calculateElectricityBill(double electricityUsage) {
    int totalCost = 0;

    if (electricityUsage <= 50) {
      totalCost = (electricityUsage * 1728).toInt();
    } else if (electricityUsage <= 100) {
      totalCost = (50 * 1728 + (electricityUsage - 50) * 2074).toInt();
    } else if (electricityUsage <= 200) {
      totalCost = (50 * 1728 + 50 * 2074 + (electricityUsage - 100) * 2612).toInt();
    } else if (electricityUsage <= 300) {
      totalCost = (50 * 1728 + 50 * 2074 + 100 * 2612 + (electricityUsage - 200) * 3290).toInt();
    } else if (electricityUsage <= 400) {
      totalCost = (50 * 1728 + 50 * 2074 + 100 * 2612 + 100 * 3290 + (electricityUsage - 300) * 3944).toInt();
    } else {
      totalCost = (50 * 1728 + 50 * 2074 + 100 * 2612 + 100 * 3290 + 100 * 3944 + (electricityUsage - 400) * 4106).toInt();
    }

    return totalCost;
  }

  /// Lưu thông tin thanh toán vào Firestore với waterUsage mặc định = 0
  void _createBillingData(
      String userId,
      String nameHouse,
      double area,
      String? fcmToken, // Nhận fcmToken từ _createUser
      Function onSuccess,
      Function(String) onRegisterError,
      ) {
    double rent = area * 200000;
    int waterPrice = 0;
    int electricPrice = 0;
    int totalAmount = rent.toInt() + waterPrice;

    var billingData = {
      "area": area.toString(),
      "rent": rent.toString(),
      "waterPrice": waterPrice,
      "waterUsage": 0, // Mức sử dụng nước mặc định
      "electricPrice": electricPrice,
      "electricUsage": 0, // Mức tiêu thụ điện ban đầu
      "totalAmount": totalAmount.toString(),
      "lastUpdated": FieldValue.serverTimestamp(),
      "fcmToken": fcmToken, // Lưu FCM token vào billing data
    };

    FirebaseFirestore.instance
        .collection('apartments')
        .doc(nameHouse)
        .collection('billing')
        .doc(userId)
        .set(billingData)
        .then((_) {
      onSuccess();
    }).catchError((err) {
      onRegisterError("Save payment information failed: $err");
    });
  }

  /// Cập nhật cả 2 tiền điện và nước khi có số liệu thực tế
  void updateBillingData({
    required String userId,
    required String nameHouse,
    required double waterUsage,
    required double electricUsage,
    required Function onSuccess,
    required Function(String) onError,
  }) {
    FirebaseFirestore.instance
        .collection('apartments')
        .doc(nameHouse)
        .collection('billing')
        .doc(userId)
        .get()
        .then((doc) {
      if (doc.exists) {
        var data = doc.data();
        double rent = double.parse(data?["rent"] ?? "0");
        int waterPrice = calculateWaterPrice(waterUsage);
        int electricPrice = calculateElectricityBill(electricUsage);
        int totalAmount = rent.toInt() + waterPrice + electricPrice;

        var updatedBillingData = {
          "waterUsage": waterUsage,
          "waterPrice": waterPrice,
          "electricUsage": electricUsage,
          "electricPrice": electricPrice,
          "totalAmount": totalAmount.toString(),
          "lastUpdated": FieldValue.serverTimestamp(),
        };

        doc.reference.update(updatedBillingData).then((_) {
          onSuccess();
        }).catchError((err) {
          onError("Cập nhật hóa đơn thất bại: $err");
        });
      } else {
        onError("Không tìm thấy thông tin hóa đơn.");
      }
    }).catchError((err) {
      onError("Lỗi lấy dữ liệu từ Firestore: $err");
    });
  }

  /// Đăng nhập người dùng
  void signIn({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onSignInError,
  }) {

    _firebaseAuth.signInWithEmailAndPassword(email: email, password: password)
        .then((userCredential) async {
      var user = userCredential.user;
      if (user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 🔹 Nếu email là 'hmvn2003@gmail.com', bỏ qua kiểm tra
        if (email == 'hmvn2003@gmail.com') {
          onSuccess();
          return;
        }

        // 🔹 Lấy `nameHouse` từ Firebase Realtime Database
        DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);
        userRef.get().then((userSnapshot) {
          if (userSnapshot.exists) {
            Map<dynamic, dynamic>? userData = userSnapshot.value as Map<dynamic, dynamic>?;
            String? nameHouse = userData?['nameHouse'];

            if (nameHouse != null) {
              DocumentReference billingRef = FirebaseFirestore.instance
                  .collection('apartments')
                  .doc(nameHouse)
                  .collection('billing')
                  .doc(user.uid);

              // 🔹 Kiểm tra document trong Firestore `apartments`
              billingRef.get().then((docSnapshot) {
                if (docSnapshot.exists) {
                  // 🔹 Cập nhật FCM token ở Firestore
                  billingRef.update({"fcmToken": fcmToken}).then((_) {
                    // 🔹 Sau khi cập nhật Firestore, tiếp tục cập nhật Realtime Database
                    userRef.update({"fcmToken": fcmToken}).then((_) {
                      onSuccess();
                    }).catchError((err) {
                      onSignInError("Cập nhật FCM token trong Realtime Database thất bại: $err");
                    });
                  }).catchError((err) {
                    onSignInError("Cập nhật FCM token trong Firestore thất bại: $err");
                  });
                } else {
                  onSignInError("Không tìm thấy hóa đơn của user trong Firestore.");
                }
              }).catchError((err) {
                onSignInError("Lỗi khi kiểm tra dữ liệu trong Firestore: $err");
              });
            } else {
              onSignInError("User không có thông tin nameHouse.");
            }
          } else {
            onSignInError("User không tồn tại trong Realtime Database.");
          }
        }).catchError((err) {
          onSignInError("Lỗi lấy dữ liệu user từ Realtime Database: $err");
        });
      } else {
        onSignInError("Đăng nhập thất bại.");
      }
    }).catchError((err) {
      onSignInError("Sign in failed, please try again.");
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
}

